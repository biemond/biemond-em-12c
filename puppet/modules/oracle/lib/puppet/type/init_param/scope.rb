newparam(:scope) do
  include EasyType

  desc "The scope of the change."

  newvalues(:SPFILE, :MEMORY)

end
