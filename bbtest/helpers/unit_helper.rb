require_relative 'eventually_helper'

require 'fileutils'
require 'timeout'
require 'thread'

Thread.abort_on_exception = true

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

class UnitHelper

  attr_reader :units

  def download()
    raise "no version specified" unless ENV.has_key?('UNIT_VERSION')

    version = ENV['UNIT_VERSION']

    FileUtils.mkdir_p "/opt/artifacts"
    %x(rm -rf /opt/artifacts/*)

    FileUtils.mkdir_p "/etc/bbtest/packages"
    %x(rm -rf /etc/bbtest/packages/*)

    %x(docker run --name temp-container-lake openbank/lake:#{version} /bin/true)
    %x(docker cp temp-container-lake:/opt/artifacts/. /opt/artifacts)
    %x(docker rm temp-container-lake)

    Dir.glob('/opt/artifacts/lake_*_amd64.deb').each { |f|
      puts "#{f}"
      FileUtils.mv(f, '/etc/bbtest/packages/lake.deb')
    }

    raise "no package to install" unless File.file?('/etc/bbtest/packages/lake.deb')
  end

  def teardown()
    return if @units.nil?

    @units.each { |unit|
      %x(systemctl stop #{unit})
      %x(journalctl -o short-precise -u #{unit} --no-pager > /reports/logs/#{unit.gsub('@','_')}.log 2>&1)

      if unit.include?("@")
        metrics_file = "/opt/#{unit[/[^@]+/]}/metrics/metrics.#{unit[/([^@]+)$/]}.json"
      else
        metrics_file = "/opt/#{unit}/metrics/metrics.json"
      end

      File.open(metrics_file, 'rb') { |fr|
        File.open("/reports/metrics/#{unit.gsub('@','_')}.json", 'w') { |fw|
          fw.write(fr.read)
        }
      } if File.file?(metrics_file)
    }
  end

end