module ActionView
  module Helpers
    class InstanceTag
      def to_label_tag(text = nil, options = {})
        options = options.stringify_keys
        name_and_id = options.dup
        name_and_id["id"] = name_and_id.delete("for") # Allowing the id attribute to be set without breaking the for attibute.
        add_default_name_and_id(name_and_id)
        options.delete("index")
        options["for"] ||= name_and_id["id"]
        content = (text.blank? ? nil : text.to_s) || method_name.humanize
        label_tag(name_and_id["id"], content, options)
      end
    end
  end
end