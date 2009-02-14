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
        define_method(method_name) do |method, *args|
          options = args.extract_options!
          args << options
          labelled_field method, super, options[:label]
        end
      end
    
      %w(text_field password_field file_field text_area check_box radio_button select date_select datetime_select collection_select).each do |name|
        create_tagged_field(name.to_sym)
      end
      
 
      def fields_for(record_or_name_or_array, *args, &block)
        opts = args.extract_options!
        opts[:builder] ||= LabeledFormBuilder
        args << opts
        
        if options.has_key?(:index)
          index = "[#{options[:index]}]"
        elsif defined?(@auto_index)
          self.object_name = @object_name.to_s.sub(/\[\]$/,"")
          index = "[#{@auto_index}]"
        else
          index = ""
        end
 
        case record_or_name_or_array
        when String, Symbol
          if nested_attributes_association?(record_or_name_or_array)
            return fields_for_with_nested_attributes(record_or_name_or_array, args, block)
          else
            name = "#{object_name}#{index}[#{record_or_name_or_array}]"
          end
        when Array
          object = record_or_name_or_array.last
          name = "#{object_name}#{index}[#{ActionController::RecordIdentifier.singular_class_name(object)}]"
          args.unshift(object)
        else
          object = record_or_name_or_array
          name = "#{object_name}#{index}[#{ActionController::RecordIdentifier.singular_class_name(object)}]"
          args.unshift(object)
        end
 
        @template.fields_for(name, *args, &block)
      end
      
      def input(method, options = {})
        labelled_field(method, ActionView::Helpers::InstanceTag.new(@object_name, method, self, options[:object] || @object).to_tag)
      end
      
      protected
      
      def nested_attributes_association?(association_name)
        @object.respond_to?("#{association_name}_attributes=")
      end
      
      def fields_for_with_nested_attributes(association_name, args, block)
        name = "#{object_name}[#{association_name}_attributes]"
        association = @object.send(association_name)

        if association.is_a?(Array)
          children = args.first.respond_to?(:new_record?) ? [args.first] : association

          children.map do |child|
            child_name = "#{name}[#{ child.new_record? ? new_child_id : child.id }]"
            @template.fields_for(child_name, child, *args, &block)
          end.join
        else
          @template.fields_for(name, association, *args, &block)
        end
      end
 
      def new_child_id
        value = (@child_counter ||= 1)
        @child_counter += 1
        "new_#{value}"
      end
      
      def labelled_field(method, field, label = nil)
        method = method.to_sym
        klass = nil
        if object.nil?
          label ||=  method.to_s
          msg = label
        else
          errors = object.errors.on(method)
          klass =  'error' unless errors.blank?
          msg = object.class.human_attribute_name method.to_s
          unless errors.blank?
            msg += ' ' + ((errors.class == Array) ? errors.join(' and ') : errors)
          end
        end
        
        @template.content_tag(:p, [
          @template.label(@object_name, method, label, objectify_options({:class => klass, :title => msg})), 
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
