class Module
  def synchronize(method, mutex_name)
    alias_method :"_unsynchronized_#{method}", method.to_sym
    define_method(method.to_sym) do |*args, &blk|
      instance_variable_get(mutex_name.to_sym).synchronize do
        send(:"_unsynchronized_#{method}", *args, &blk)
      end
    end
  end
end

