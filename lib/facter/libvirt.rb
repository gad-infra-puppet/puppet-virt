# virt_libvirt.rb

class CachedLibvirtConnection
  @connection = nil
  @cached = false

  def self.get
    cache_connection if not @cached
    @connection
  end

  private

  def self.cache_connection
    require 'libvirt'
    @connection = Libvirt::open('qemu:///system')
    @cached = true
  rescue LoadError
    # ruby-libvirt not installed
    @connection = nil
    @cached = true
  rescue Libvirt::Error => e
    raise
  end
end

def libvirt_connect
  if block_given?
    begin
      c = nil
      require 'libvirt'
      yield c = Libvirt::open('qemu:///system')
    rescue LoadError
      # ruby-libvirt not installed
      yield nil
    rescue
      raise
    ensure
      c.close unless c.nil?
    end
  else
    CachedLibvirtConnection.get
  end
end

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

def add_fact_from_libvirt_conn(name)
  Facter.add(name) do
    confine :virt_libvirt => true
    confine :virt_conn => true
    setcode do
      begin
        libvirt_connect { |conn| yield conn }
      rescue Libvirt::Error, NoMethodError => e
        warn(e)
        nil
      end
    end
  end
end

def add_fact_from_libvirt_property(fact_name, libvirt_property, &block)
  add_fact_from_libvirt_conn(fact_name) do |conn|
    value = conn.send(libvirt_property)
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

add_fact_from_libvirt_property("virt_conn_type", "type")
add_fact_from_libvirt_property("virt_hypervisor_version", "version")
add_fact_from_libvirt_property("virt_libvirt_version", "libversion")
add_fact_from_libvirt_property("virt_hostname", "hostname")
add_fact_from_libvirt_property("virt_uri", "uri")
add_fact_from_libvirt_conn("virt_max_vcpus") { |conn| conn.max_vcpus('qemu') }
add_fact_from_libvirt_property("virt_domains_active", "list_domains") do |conn, domid|
  conn.lookup_domain_by_id(domid).name
end
add_fact_from_libvirt_property("virt_domains_inactive", "list_defined_domains")
add_fact_from_libvirt_property("virt_networks_active", "list_networks")
add_fact_from_libvirt_property("virt_networks_inactive", "list_defined_networks")
add_fact_from_libvirt_property("virt_nodes", "list_nodedevices")
add_fact_from_libvirt_property("virt_nwfilters", "list_nwfilters")
add_fact_from_libvirt_property("virt_secrets", "list_secrets")
add_fact_from_libvirt_property("virt_storage_pools_active", "list_storage_pools")
add_fact_from_libvirt_property("virt_storage_pools_inactive", "list_defined_storage_pools")
