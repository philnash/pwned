module DeepMerge
  refine Hash do
    def deep_merge(other)
      self.merge(other) do |key, this_val, other_val|
        if this_val.is_a?(Hash) && other_val.is_a?(Hash)
          this_val.deep_merge(other_val)
        else
          other_val
        end
      end
    end
  end
end