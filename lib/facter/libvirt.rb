# virt_libvirt.rb

Facter.add("virt_libvirt") do
  setcode do
    begin
      require 'libvirt'
      true
    rescue LoadError
      false
    end
  end
end

Facter.add("virt_conn") do
  confine :virt_libvirt => true
  setcode do
    begin
      libvirt_connect { |c| true }
    rescue Libvirt::Error, NoMethodError
      false
    end
  end
end

def libvirt_connect
  # libvirt already loaded because "confine :virt_libvirt => true" in all facts
  c = nil
  yield c = Libvirt::open('qemu:///system')
ensure
  c.close unless c.nil?
end


# helper to add facts from libvirt attributes and/or methods
class LibvirtFacter

  def self.add(name)
    LibvirtFacter.new(name)
  end

  # Add a fact computed from a libvirt attribute
  # For a string attribute, the fact value is chomped
  # For an array attribute, the fact value is a string made of
  # array elements joined with commas
  # If the libvirt attribute is an array and a block is given,
  # then the block will be applied on every element of the array
  def from_attribute(attribute, &block)
    from_connection do |conn|
      value = conn.send(attribute)
      return nil if value.nil?

      if value.kind_of?(Array)
        if block_given?
          value.collect! { |e| block.call(conn, e) }
        end
        value.join(',')
      else
        value.to_s.chomp
      end
    end
  end

  # the block is given a libvirt connection and must return the fact value
  def from_connection(&block)
    Facter.add(@name) do
      confine :virt_libvirt => true
      confine :virt_conn => true
      setcode do
        begin
          libvirt_connect &block
        rescue Libvirt::Error, NoMethodError => e
          warn(e)
          nil
        end
      end
    end
  end

  private

  def initialize(name)
    @name = name
  end
end


LibvirtFacter.add("virt_conn_type").from_attribute("type")
LibvirtFacter.add("virt_hypervisor_version").from_attribute("version")
LibvirtFacter.add("virt_libvirt_version").from_attribute("libversion")
LibvirtFacter.add("virt_hostname").from_attribute("hostname")
LibvirtFacter.add("virt_uri").from_attribute("uri")
LibvirtFacter.add("virt_max_vcpus").from_connection { |conn| conn.max_vcpus("qemu") }
LibvirtFacter.add("virt_domains_active").from_attribute("list_domains") do |conn, domid|
  conn.lookup_domain_by_id(domid).name
end
LibvirtFacter.add("virt_domains_inactive").from_attribute("list_defined_domains")
LibvirtFacter.add("virt_networks_active").from_attribute("list_networks")
LibvirtFacter.add("virt_networks_inactive").from_attribute("list_defined_networks")
LibvirtFacter.add("virt_nodes").from_attribute("list_nodedevices")
LibvirtFacter.add("virt_nwfilters").from_attribute("list_nwfilters")
LibvirtFacter.add("virt_secrets").from_attribute("list_secrets")
LibvirtFacter.add("virt_storage_pools_active").from_attribute("list_storage_pools")
LibvirtFacter.add("virt_storage_pools_inactive").from_attribute("list_defined_storage_pools")
