module DiMarcello
  module LabeledForm
    autoload :LabeledFormBuilder, File.join(File.dirname(__FILE__), 'labeled_form', 'labeled_form_builder')
    autoload :LabeledFormHelper, File.join(File.dirname(__FILE__), 'labeled_form', 'labeled_form_helper')
    
    ActionView::Base.send :include, LabeledFormHelper
  end
end