# frozen_string_literal: true

require 'sinatra'
require 'nokogiri'
require 'open3'
require 'bundler'

set :bind, '0.0.0.0'
set :port, 9112

PASSENGER_STATUS_COMMAND = "bash -lc 'rvm use ruby-2.7.8 > /dev/null && passenger-status --show=xml'"

get '/' do
  'Passenger Exporter running - use /metrics'
end

get '/metrics' do
  metrics = fetch_passenger_metrics
  if metrics.is_a?(String)
    # Error message returned
    status 500
    return metrics
  end

  content_type 'text/plain'
  "#{metrics.map { |k, v| "#{k} #{v}" }.join("\n")}\n"
end

def fetch_passenger_metrics
  Bundler.with_unbundled_env do
    stdout, stderr, status = Open3.capture3(PASSENGER_STATUS_COMMAND)
    return "# Error executing passenger-status: #{stderr}" unless status.success?

    parse_passenger_status_xml(stdout)
  end
end

def parse_passenger_status_xml(xml_str)
  metrics = {}
  parse_xml_and_extract_metrics(xml_str, metrics)
  metrics
end

def parse_xml_and_extract_metrics(xml_str, metrics)
  xml = xml_str.force_encoding('ISO-8859-1').encode('UTF-8')
  doc = Nokogiri::XML(xml)
  extract_main_metrics(doc, metrics)
  extract_process_metrics(doc, metrics)
  debug_metrics(metrics)
rescue StandardError => e
  handle_parse_error(e)
end

def handle_parse_error(error)
  "# Error parsing XML: #{error.message}"
end

def extract_main_metrics(doc, metrics)
  metrics['passenger_capacity_used'] = doc.at_xpath('//capacity_used')&.text.to_i
  metrics['passenger_max_pool_size'] = doc.at_xpath('//max')&.text.to_i
  metrics['passenger_wait_list_size'] = doc.at_xpath('//get_wait_list_size')&.text.to_i
  metrics['passenger_processes_being_used'] = doc.xpath('//process').count
end

def extract_process_metrics(doc, metrics)
  doc.xpath('//process').each_with_index do |proc, idx|
    process_metrics = parse_process_metrics(proc)
    process_metrics.each do |key, value|
      metrics["passenger_process_#{idx}_#{key}"] = value
    end
  end
end

def parse_process_metrics(proc)
  cpu = proc.at_xpath('cpu')&.text.to_f
  rss_kb = proc.at_xpath('rss')&.text.to_i
  sessions = proc.at_xpath('sessions')&.text.to_i
  uptime_str = proc.at_xpath('uptime')&.text

  {
    'cpu_percent' => cpu,
    'memory_mb' => (rss_kb / 1024.0).round(2),
    'uptime_seconds' => parse_uptime(uptime_str),
    'sessions' => sessions
  }
end

def debug_metrics(metrics)
  metrics.each { |k, v| puts "[DEBUG] #{k}: #{v}" }
end

def parse_uptime(uptime_str)
  return 0 unless uptime_str

  total_seconds = 0
  uptime_str.scan(/(\d+)\s*h/) { |h| total_seconds += h[0].to_i * 3600 }
  uptime_str.scan(/(\d+)\s*m/) { |m| total_seconds += m[0].to_i * 60 }
  uptime_str.scan(/(\d+)\s*s/) { |s| total_seconds += s[0].to_i }
  total_seconds
end
