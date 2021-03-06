# A cache store implementation which stores everything into memory in the
# same process. If you're running multiple Ruby on Rails server processes
# (which is the case if you're using mongrel_cluster or Phusion Passenger),
# then this means that your Rails server process instances won't be able
# to share cache data with each other.
#
# EnhancedMemoryStore extends the default Rails MemoryStore, adding
# the :expires_in option, so that it is compatible with the
# MemCacheStore. It stores values in a nested hash, like so:
#   { :value => value, :expires_at => expiry_timestamp }
#
# EnhancedMemoryStore is not only able to store strings, but also
# arbitrary Ruby objects.
#
# EnhancedMemoryStore is not thread-safe. Use SynchronizedMemoryStore instead
# if you need thread-safety.
module ActiveSupport
  module Cache
    class EnhancedMemoryStore < MemoryStore

      # Reads a value from the cache.
      #
      # If the entry has expired, it will be purged.
      def read(name, options = nil)
        wrapper = super(name, options)
        if wrapper && wrapper.kind_of?(Hash)
          if wrapper[:expires_at]
            if wrapper[:expires_at] > Time.now
              # fresh
              wrapper[:value]
            else
              # stale
              delete(name)
              nil
            end
          else
            # no expiry
            wrapper[:value]
          end
        else
          # no wrapper; return raw result
          wrapper
        end
      end

      # Writes a value to the cache.
      #
      # Possible options:
      # - +:unless_exist+ - set to true if you don't want to update the cache
      #   if the key is already set.
      # - +:expires_in+ - the number of seconds that this value may stay in
      #   the cache. See ActiveSupport::Cache::Store#write for an example.
      def write(name, value, options = nil)
        # check :unless_exist option
        return nil if options && options[:unless_exist] && exist?(name)

        # create wrapper with expiry data
        wrapper = if options && options[:expires_in]
                    { :value => value, :expires_at => expires_in(options).from_now }
                  else
                    { :value => value }
                  end

        # call ActiveSupport::Cache::MemoryStore#write
        super(name, wrapper, options)
      end
    end
  end
end
