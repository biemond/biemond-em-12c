require 'ora_utils/mungers'

newparam(:name) do
  include EasyType
  include EasyType::Validators::Name
  include OraUtils::Mungers::LeaveSidRestToUppercase

  desc "The parameter name"

  isnamevar

  to_translate_to_resource do | raw_resource|
    sid = raw_resource.column_data('SID')
    instance = raw_resource.column_data('INSTANCE_NAME')
    parameter_name = raw_resource.column_data('NAME').upcase
    scope = raw_resource.column_data('SCOPE').upcase
    "#{scope}/#{parameter_name}:#{instance}@#{sid}"
	end

end

