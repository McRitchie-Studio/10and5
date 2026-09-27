# One thing a department should do on every visit, scored pass, fail or N/A.
Standard = Data.define(:id, :text, :department_key) do
  def department = Sample.department(department_key)
end
