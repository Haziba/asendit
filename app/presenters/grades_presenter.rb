class GradesPresenter
  attr_reader :grades, :user

  def initialize(grades, user = nil)
    @grades = grades
    @user = user
  end

  def present
    {
      grades: grades.map { |grade| GradePresenter.new(grade, user).present_summary }
    }
  end
end