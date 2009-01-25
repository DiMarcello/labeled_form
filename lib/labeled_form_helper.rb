# LabeledForm
module ActionView
  module Helpers
    module LabeledFormHelper
      def labeled_form_for( *args, &block )
        raise ArgumentError, "Missing block" unless block_given?
        options = args.extract_options!.merge( :builder => LabeledFormBuilder )
        form_for( *(args << options), &block )
      end
    end
    
    class LabeledFormBuilder < FormBuilder
      def self.create_tagged_field(method_name)
        define_method(method_name) do |label, *args|
          labelled_field label, super
        end
      end
    
      %w(text_field password_field file_field text_area check_box radio_button date_select datetime_select collection_select).each do |name|
        create_tagged_field(name.to_sym)
      end
      
      def fields_for(*args, &block)
        options = args.extract_options!
        options[:builder] ||= LabeledFormBuilder
        super(*(args << options), &block)
      end
      
      def input(method, options = {})
        labelled_field(method, ActionView::Helpers::InstanceTag.new(@object_name, method, self, options[:object] || @object).to_tag)
      end
      
      protected
      
      def labelled_field(method, field)
        label = method.to_s
        method = method.to_sym
        errors = object.errors.on(method)
        klass = errors.blank? ? nil : 'error'
        msg = object.class.human_attribute_name label
        unless errors.blank?
          msg += ' ' + ((errors.class == Array) ? errors.join(' and ') : errors)
        end
        
        @template.content_tag(:p, [
          @template.content_tag(:label, "#{label.to_s.humanize}:", :for => "#{@object_name}_#{label}", :class => klass, :title => msg), 
          field
        ].join(" "))
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
    end
  end
end

ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
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
