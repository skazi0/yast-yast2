# Copyright (c) [2021] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require "yast"
require "yast2/issues/issue"

module Yast2
  module Issues
    # Represents a situation where an invalid value was given
    class InvalidValue < Issue
      # @param location [URI, String] Error location ("file:/etc/sysconfig/ifcfg-eth0:BOOTPROTO")
      # @param value [#to_s] Invalid value
      # @param fallback [#to_s] Value to use instead of the invalid one
      def initialize(value, location:, fallback: nil, severity: :warn)
        msg = format(_("Invalid value '%{value}'."), value: value)
        msg << " " + format(_("Using '%{fallback}' instead."), fallback: fallback) if fallback

        super(msg, location: location, severity: severity)
      end
    end
  end
end
