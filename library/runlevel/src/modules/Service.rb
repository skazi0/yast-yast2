# ***************************************************************************
#
# Copyright (c) 2002 - 2014 Novell, Inc.
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#
# ***************************************************************************
# File:	modules/Service.ycp
# Package:	yast2
# Summary:	Service manipulation
# Authors:	Martin Vidner <mvidner@suse.cz>
#		Petr Blahos <pblahos@suse.cz>
#		Michal Svec <msvec@suse.cz>
#		Lukas Ocilka <locilka@suse.cz>
###

# Functions for systemd service handling used by other modules.

require "yast"

module Yast
  import "SystemdService"

  class ServiceClass < Module
    include Yast::Logger

    attr_accessor :error

    def initialize
      textdomain "base"
      @error = ""
    end

    # Check if service is active/running
    #
    # @param [String] name service name
    # @return true if service is active
    def Active service_name
      service = SystemdService.find(service_name)
      !!(service && service.active?)
    end

    alias_method :active?, :Active

    # Check if service is enabled (in any runlevel)
    #
    # Forwards to chkconfig -l which decides between init and systemd
    #
    # @param [String] name service name
    # @return true if service is set to run in any runlevel
    def Enabled name
      service = SystemdService.find(name)
      !!(service && service.enabled?)
    end

    alias_method :enabled?, :Enabled

    # Enable service
    # @param [String] service service to be enabled
    # @return true if operation is successful
    def Enable service_name
      log.info "Enabling service %1", service_name
      service = SystemdService.find(service_name)
      return failure(:not_found, service_name) unless service
      return failure(:enable, service_name, service.error) unless service.enable
      true
    end

    alias_method :enable, :Enable

    # Disable service
    # @param [String] service service to be disabled
    # @return true if operation is  successful
    def Disable service_name
      log.info "Disabling service %1", service_name
      service = SystemdService.find(service_name)
      return failure(:not_found, service_name) unless service
      return failure(:disable, service_name, service.error) unless service.disable
      true
    end

    alias_method :disable, :Disable

    # Start service
    # @param [String] service service to be started
    # @return true if operation is  successful
    def Start service_name
      log.info "Starting service %1", service_name
      service = SystemdService.find(service_name)
      return failure(:not_found, service_name) unless service
      return failure(:start, service_name, service.error) unless service.start
      true
    end

    alias_method :start, :Start

    # Restart service
    # @param [String] service service to be restarted
    # @return true if operation is  successful
    def Restart service_name
      log.info "Restarting service %1", service_name
      service = SystemdService.find(service_name)
      return failure(:not_found, service_name) unless service
      return failure(:restart, service_name, service.error) unless service.restart
      true
    end

    alias_method :restart, :Restart

    # Reload service
    # @param [String] service service to be reloaded
    # @return true if operation is  successful
    def Reload service_name
      log.info "Reloading service %1", service_name
      service = SystemdService.find(service_name)
      return failure(:not_found, service_name) unless service
      return failure(:reload, service_name, service.error) unless service.reload
      true
    end

    alias_method :reload, :Reload

    # Stop service
    # @param [String] service service to be stopped
    # @return true if operation is  successful
    def Stop service_name
      log.info "Stopping service %1", service_name
      service = SystemdService.find(service_name)
      return failure(:not_found, service_name) unless service
      return failure(:stop, service_name, service.error) unless service.stop
      true
    end

    alias_method :stop, :Stop

    # Error Message
    #
    # If a Service function returns an error, this function would return
    # an error message, including insserv stderr and possibly containing
    # newlines.
    # @return error message from the last operation
    def Error
      error
    end

    # @deprecated Use SystemdService.find
    # Check that a service exists.
    # If not, set error_msg.
    # @param [String] name service name without a path, eg. nfsserver
    # @return Return true if the service exists.
    def checkExists name
      deprecate("use `SystemdService.find` instead")

      return failure(:not_found, name) unless SystemdService.find(name)
      true
    end

    # @deprecated Not supported by systemd
    # Get service info without peeking if service runs.
    # @param [String] name name of the service
    # @return Service information or empty map ($[])
    def Info name
      deprecate("not supported by systemd")

      unit = SystemdService.find(name)
      return {} unless unit

      read = Convert.to_map(SCR.Read(path(".init.scripts.runlevel"), name))
      detail = Ops.get_map(read, name, {})
      read = Convert.to_map(SCR.Read(path(".init.scripts.comment"), name))
      service = Ops.get_map(read, name, {})
      Builtins.add(
        Builtins.add(service, "start", Ops.get_list(detail, "start", [])),
        "stop",
        Ops.get_list(detail, "stop", [])
      )
    end

    # @deprecated Use SystemdService.find('service_name').id
    # Get complete systemd unit id
    # @param name name or alias of the unit
    # @return (resolved) unit Id
    def GetUnitId unit
      deprecate("use SystemdService.find('service_name').id")

      unit = SystemdService.find(unit)
      return nil unless unit
      unit.id
    end

    # @deprecated Use SystemdService.find('service_name').name
    # Get the name from a systemd service unit id without the .service suffix
    # @param [String] name name or alias of the service
    # @return (resolved) service name without the .service suffix
    def GetServiceId name
      deprecate("use SystemdService.find('service_name').name")

      unit = SystemdService.find(name)
      return nil unless unit
      unit.name
    end

    # @deprecated Use `Active` instead
    # Get service status.
    # The status is the output from "service status".
    # It should conform to LSB. 0 means the service is running.
    # @param [String] name name of the service
    # @return init script exit status or -1 if it does not exist
    def Status name
      deprecate("use `active?` instead")

      unit = SystemdService.find(name)
      failure(:not_found, name) unless unit

      unit && unit.active? ? 0 : -1
    end

    # @deprecated Not supported by systemd
    # Get service info and find out whether service is running.
    # @param [String] name name of the service
    # @return service map or empty map ($[])
    def FullInfo name
      deprecate("not supported by systemd")

      return {} if !checkExists(name)
      Builtins.add(Info(name), "started", Status(name))
    end

    # @deprecated Use `Disable` instead
    # Disables a given service and records errors.
    # Does not check if it exists.
    #
    # @param [String] name service name
    # @param [Boolean] force pass "--force" (workaround for #17608, #27370)
    # @return success state
    def serviceDisable name, force
      deprecate("use `disable` instead")

      unit = SystemdService.find(name)
      !!(unit && unit.disable)
    end

    # @deprecated Use the specific methods: `Enable` or `Disable`
    # Adjusts runlevels in which the service runs.
    #
    # @param string service name
    # @param [String] action "disable" -- remove links, "enable" -- if there are
    #    no links, set default, otherwise do nothing, "default" -- set
    #    defaults.
    # @return [Boolean] success state
    def Adjust name, action
      deprecate("use `enable` or `disable` instead")

      service = SystemdService.find(name)
      return failure(:not_found, name) unless service

      case action
      when "disable"
        service.disable
      when "enable", "default"
        service.enable
      else
        log.error "Unknown action '#{action}' for service '#{name}'"
        false
      end
    end

    # @deprecated Use `Enable` or `Disable` instead
    # Set service to run in selected runlevels.
    # Obsoleted - enables or disables the given service depending on the
    # list of runlevels to start. If any runlevel is present, service is
    # enabled, otherwise disabled.
    #
    # @param [String] name name of service to adjust
    # @param [Array] rl list of runlevels in which service should start
    # @return success state
    def Finetune name, rl
      deprecate("use `enable` or `disable` instead")

      service = SystemdService.find(name)
      return failure(:not_found, name) unless service

      if rl.empty?
        service.disable
      else
        log.warn "Cannot enable service '#{name}' in selected runlevels, enabling for all"
        service.enable
      end
    end

    # @deprecated Use specific method for service configuration
    # Run init script.
    # @param [String] name init service name
    # @param [String] param init script argument
    # @return [Fixnum] exit value
    def RunInitScript name, param
      deprecate("use `start` or `stop` instead")

      service = SystemdService.find(name)
      if !service
        failure(:not_found, name)
        return -1
      end

      case param
      when 'start'
        service.start
      when 'stop'
        service.stop
      else
        log.error "Unknown action '#{param}' for service '#{name}'"
        return -1
      end
      0
    end

    # @deprecated Use specific unit methods for service configuration
    # Run init script with a time-out.
    # @param [String] name init service name
    # @param [String] param init script argument
    # @return [Fixnum] exit value
    def RunInitScriptWithTimeOut name, param
      deprecate("use `start` or `stop` instead")

      service = SystemdService.find(name)
      if !service
        failure(:not_found, name)
        return 1
      end
      service.send(param) ? 0 : 1
    end

    # @deprecated Use a specific method instread
    # Run init script and also return its output (stdout and stderr merged).
    # @param [String] name init service name
    # @param [String] param init script argument
    # @return A map of $[ "stdout" : "...", "stderr" : "...", "exit" : int]
    def RunInitScriptOutput name, param
      deprecate("use `start` or `stop` instead")

      service = SystemdService.find(name)
      if !service
        failure(:not_found, name)
        success = false
      else
        success = service.send(param)
        self.error = service.error
      end
      {'stdout'=>'', 'stderr'=>error, 'exit'=> success ? 0 : 1 }
    end

    # @deprecated Runlevel features are not supported by systemd
    # Get list of enabled services in a runlevel
    # @param [Fixnum] runlevel requested runlevel number (0-6, -1 = Single)
    # @return [Array<String>] enabled services
    def EnabledServices runlevel
      deprecate("use `SystemdService.all.select(&:enabled?)`")

      SystemdService.all.select(&:enabled?).map(&:name)
    end

    # @deprecated Use SystemdService.find instead
    # Return the first of the list of services which is available
    # (has init script) or "" if none is.
    # @param list<string> list of service names
    # @return [String] the first found service
    def Find services
      deprecate("use `SystemdService.find` instead")

      service_found = nil
      services.each do |service_name|
        service = SystemdService.find(service_name)
        if service
          service_found = service_name
          break
        end
      end
      service_found
    end

    private

    def failure event, service_name, error=""
      case event
      when :not_found
        error << "Service '#{service_name}' not found"
      else
        error.prepend("Attempt to `#{event}` service '#{service_name}' failed. ")
      end
      self.error = error
      log.error(error)
    ensure
      return false
    end


    def deprecate message
      log.warn "[DEPRECIATION] #{caller[0].split.last} is deprecated; #{message}"
    end

    publish :function => :GetUnitId, :type => "string (string)"
    publish :function => :GetServiceId, :type => "string (string)"
    publish :function => :Enabled, :type => "boolean (string)"
    publish :function => :Info, :type => "map (string)"
    publish :function => :Status, :type => "integer (string)"
    publish :function => :FullInfo, :type => "map (string)"
    publish :function => :Adjust, :type => "boolean (string, string)"
    publish :function => :Finetune, :type => "boolean (string, list)"
    publish :function => :RunInitScript, :type => "integer (string, string)"
    publish :function => :RunInitScriptWithTimeOut, :type => "integer (string, string)"
    publish :function => :RunInitScriptOutput, :type => "map (string, string)"
    publish :function => :Enable, :type => "boolean (string)"
    publish :function => :Disable, :type => "boolean (string)"
    publish :function => :Start, :type => "boolean (string)"
    publish :function => :Restart, :type => "boolean (string)"
    publish :function => :Reload, :type => "boolean (string)"
    publish :function => :Stop, :type => "boolean (string)"
    publish :function => :Error, :type => "string ()"
    publish :function => :EnabledServices, :type => "list <string> (integer)"
    publish :function => :Find, :type => "string (list <string>)"
  end
  Service = ServiceClass.new
end
