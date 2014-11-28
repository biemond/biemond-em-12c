newparam(:instance) do
  include EasyType
  include EasyType::Validators::Name
  desc "The instance name"

  isnamevar

  defaultto 'default'

  to_translate_to_resource do | raw_resource|
    raw_resource.column_data('INSTANCE_NAME')
  end

  def instance
  	self[:instance].empty? ? self[:sid] : self[:instance]
  end
end