# Include hook code here
require 'labeled_form_helper'

ActionView::Base.class_eval do
  include ActionView::Helpers::LabeledFormHelper
end
ActionView::Base.default_form_builder = ActionView::Helpers::LabeledFormBuilder