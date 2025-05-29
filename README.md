# Passenger Exporter for Prometheus

This project is a metrics exporter for Passenger web server, developed in Ruby, to be integrated with Prometheus. It exposes Passenger metrics (passenger-status) in a Prometheus-compatible format, making it easy to monitor Ruby on Rails applications.

## Features
- Exports Passenger metrics such as capacity usage, processes, sessions, CPU, and memory.
- Exposes metrics at `/metrics` in Prometheus format.
- Ready to run as a systemd service.

## Prerequisites
- RVM/Ruby (Change the value of PASSENGER_STATUS_COMMAND according to your preferred Ruby version)
- Passenger installed and configured
- Bundler
- Prometheus

## Installation
1. Clone this repository:
   ```sh
   git clone https://github.com/kasyd/passenger-exporter-ruby.git
   cd passenger-exporter-ruby
   ```
2. Install dependencies:
   ```sh
   bundle install
   ```
3. Copy the files to the desired directory (e.g., `/opt/passenger_exporter`).

## systemd Service Configuration
Create the file `/etc/systemd/system/passenger-exporter.service` with the following content:

```ini
[Unit]
Description=Passenger Exporter for Prometheus
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/opt/passenger_exporter
ExecStart=/opt/passenger_exporter/start.sh
Restart=always

[Install]
WantedBy=multi-user.target
```

Then run:
```sh
sudo systemctl daemon-reload
sudo systemctl enable passenger-exporter
sudo systemctl start passenger-exporter
```

## Prometheus Configuration
Add the following configuration to your `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'passenger'
    static_configs:
      - targets: ['localhost:9112']
```

Then reload Prometheus:
```sh
sudo systemctl reload prometheus
```

## Usage Example
Access `http://localhost:9112/metrics` to view the exported metrics.

## Troubleshooting
- Make sure Passenger is installed and accessible by the service user.
- Check if RVM is properly configured for the user.
- Check systemd logs for error messages:
  ```sh
  journalctl -u passenger-exporter
  ```

## License
MIT License.

## Contributions
Pull requests are welcome!

