module DiMarcello
  module LabeledForm
    autoload :LabeledFormBuilder, File.join(File.dirname(__FILE__), 'labeled_form', 'labeled_form_builder')
    autoload :LabeledFormHelper, File.join(File.dirname(__FILE__), 'labeled_form', 'labeled_form_helper')
    require File.join(File.dirname(__FILE__), 'labeled_form', 'instance_tag')
    
    ActionView::Base.send :include, LabeledFormHelper
  end
end