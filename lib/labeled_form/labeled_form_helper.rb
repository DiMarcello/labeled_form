# LabeledForm
module DiMarcello
  module LabeledForm
    module LabeledFormHelper
      def labeled_form_for( *args, &block )
        raise ArgumentError, "Missing block" unless block_given?
        options = args.extract_options!.merge( :builder => LabeledFormBuilder )
        form_for( *(args << options), &block )
      end
    end
  end
end