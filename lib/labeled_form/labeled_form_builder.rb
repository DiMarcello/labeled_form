module DiMarcello
  module LabeledForm
    # TODO Move label options to: :label => {:text => "Label", :position => :after, :class => "test"}
    # TODO Do something with the error wrap.
    class LabeledFormBuilder < ActionView::Helpers::FormBuilder
      HELPERS = [
        ActionView::Helpers::FormBuilder.field_helpers + 
        %w(date_select datetime_select time_select collection_select select country_select time_zone_select) - 
        %w(hidden_field label fields_for submit)
      ].flatten.freeze
      
      private
      
      def self.create_tagged_field(method_name, label = true)
        define_method(method_name) do |method, *args|
          options = args.extract_options!
          
          label_options = extract_label_options(options)
          label_options[:position] ||= :after if [:check_box, :radio_button].include?(method_name)
          wrap = options.delete :wrap
          args << options
          
          field = super(method, *args)
          field = labeled_field(method, field, label_options) if label
          tagged_field(field, wrap)
        end
      end
      
      public
      
      HELPERS.each do |name|
        create_tagged_field(name.to_sym)
      end
      create_tagged_field(:submit, false)
      
      def fieldset_for(method, *args, &block)
        options = args.extract_options!
        builder = options.delete(:builder) || self.class
        
        legend = options.delete(:legend)
        unless legend == false
          legend ||= object.nil? ? method.to_s.humanize : object.class.human_attribute_name(method.to_s)
        end
        
        @template.concat(@template.tag(:fieldset, options, true))
        @template.concat(@template.content_tag(:legend, legend)) unless legend.blank?
        fields_for(method, *(args << {:builder => builder}), &block)
        @template.concat('</fieldset>')
      end
      
      def fields_for(*args, &block)
        options = args.extract_options!
        options[:builder] ||= self.class
        super(*(args << options), &block)
      end
      
      def input(method, options = {})
        labeled_field(method, ActionView::Helpers::InstanceTag.new(@object_name, method, self, options[:object] || @object).to_tag)
      end
      
      protected
      
      def tagged_field(field, tag = true)
        return field if tag == false
        tag = :p if tag == true || tag.blank?
        @template.content_tag(tag, field)
      end
      
      def labeled_field(method, field, options = {})
        return field if options[:text] == false
        method, label = method.to_s, options.delete(:text)
        klass, msg = nil
        
        if object.nil?
          label ||= method.humanize
          msg = label
        else
          errors  = object.errors.on(method)
          label ||= object.class.human_attribute_name method
          msg     = label
          unless errors.blank?
            klass = 'error'
            msg  += ' ' + ((errors.class == Array) ? errors.join(' and ') : errors)
          end
        end
        
        options[:class] = [options[:class], klass].compact.join(" ") unless klass.nil?
        options[:title] ||= msg
        position = options.delete :position
        
        fields = [@template.label(@object_name, method, label, objectify_options(options)), field]
        fields.reverse! if position == :after
        fields.join("")
      end
      
      def error_wrap_field(html_tag)
        error_class = "error"
        if html_tag =~ /<(input|textarea|select)[^>]+class=/
          class_attribute = html_tag =~ /class=['"]/
          html_tag.insert(class_attribute + 7, "#{error_class} ")
        elsif html_tag =~ /<(input|textarea|select)/
          first_whitespace = html_tag =~ /\s/
          html_tag[first_whitespace] = " class='#{error_class}' "
        end
        html_tag
      end
      
      def extract_label_options(options)
        label_options = options.delete :label
        label_options = {:text => label_options} unless label_options.is_a? Hash
        label_options
      end
    end
  end
end