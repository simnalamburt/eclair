# frozen_string_literal: true
require 'eclair/item'
require 'eclair/providers/k8s/k8s_provider'
require 'time'

module Eclair
  class K8sItem < Item
    attr_reader :pod

    def initialize pod
      super()
      @pod = pod
    end

    def id
      @pod["metadata"]["uid"]
    end

    def color
      if @selected
        [Curses::COLOR_YELLOW, -1, Curses::A_BOLD]
      elsif !connectable?
        [Curses::COLOR_BLACK, -1, Curses::A_BOLD]
      else
        [Curses::COLOR_WHITE, -1]
      end
    end

    def exec_command
      @pod["metadata"]["labels"]["eclair_exec_command"] || "/bin/sh"
    end

    def command
      "kubectl exec --namespace #{namespace} -ti #{name} #{exec_command}"
    end

    def header
      <<-EOS
      #{name}
      launched at #{launch_time.to_time}
      EOS
    end

    def label
      " - #{name} [#{launched_at}]"
    end

    def namespace
      @pod["metadata"]["namespace"]
    end

    def name
      @pod["metadata"]["name"]
    end

    def connectable?
      status == "running"
    end

    def search_key
      name.downcase
    end

    private

    def status
      @pod["status"]["containerStatuses"].first["state"].keys.first rescue nil
    end

    def launch_time
      Time.parse(@pod["metadata"]["creationTimestamp"])
    end

    def launched_at
      diff = Time.now - launch_time
      {
        "year" => 31557600,
        "month" => 2592000,
        "day" => 86400,
        "hour" => 3600,
        "minute" => 60,
        "second" => 1
      }.each do |unit,v|
        if diff >= v
          value = (diff/v).to_i
          return "#{value} #{unit}#{value > 1 ? "s" : ""}"
        end
      end
      "now"
    end
  end
end
