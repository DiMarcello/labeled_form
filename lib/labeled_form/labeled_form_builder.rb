module DiMarcello
  module LabeledForm
    #TODO add label_position option
    class LabeledFormBuilder < ActionView::Helpers::FormBuilder
      LABELED_OPTIONS = [:label, :wrap]
      
      private
      def self.create_tagged_field(method_name, label = true)
        define_method(method_name) do |method, *args|
          options = args.extract_options!
          labeled_options = extract_labeled_options(options)
          args << options
          
          field = super(method, *args)
          field = labeled_field(method, field, labeled_options[:label]) if label
          tagged_field(field, labeled_options[:wrap])
        end
      end
      
      public
      %w(text_field password_field file_field text_area check_box radio_button select date_select datetime_select time_select collection_select).each do |name|
        create_tagged_field(name.to_sym)
      end
      
      %w(submit).each do |name|
        create_tagged_field(name.to_sym, false)
      end
      
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
        
      def input(method, options = {})
        labeled_field(method, ActionView::Helpers::InstanceTag.new(@object_name, method, self, options[:object] || @object).to_tag)
      end
      
      protected
      
      def tagged_field(field, tag = true)
        return field if tag == false
        tag = :p if tag == true || tag.blank?
        @template.content_tag(tag, field)
      end
      
      def labeled_field(method, field, label = nil)
        return field if label == false
        method = method.to_sym
        klass = nil
        if object.nil?
          label ||= method.to_s.humanize
          msg = label
        else
          errors = object.errors.on(method)
          klass =  'error' unless errors.blank?
          msg = object.class.human_attribute_name method.to_s
          unless errors.blank?
            msg += ' ' + ((errors.class == Array) ? errors.join(' and ') : errors)
          end
        end
        
        [ @template.label(@object_name, method, label, objectify_options({:class => klass, :title => msg})), 
          field ].join("")
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
      
      def extract_labeled_options(options)
        returning({}) do |o|
          LABELED_OPTIONS.each do |k|
            o[k] = options.delete k
          end
        end
      end
    end
  end
end