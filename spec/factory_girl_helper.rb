module FactoryGirlHelper
  def find_or_create(*args)
    name = args.shift
    clazz = nil

    # convert from underscores String to camelcase Class
    if name.is_a? Hash
      name = name.first[0]
      clazz = name.first[1].to_s.camelize.constantize
    else
      clazz = name.to_s.camelize.constantize
    end

    target = nil

    # Create Arel lookup to see if model already exists
    lookup = args.shift
    target = clazz.where(lookup).first unless lookup.empty?

    # if the model was not found, create a new one
    target = FactoryGirl.create(name, lookup) if target.nil?

    target
  end
end
