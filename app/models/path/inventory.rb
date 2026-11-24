# What one profession holds, counted once per request for the hero, the tabs and the doors.
class Path::Inventory
  def initialize(path)
    @path = path
  end

  def chapters = @chapters ||= @path.courses.published.count
  def lessons = kinds["lesson"].to_i
  def tasks = kinds["practice"].to_i
  def documents = @documents ||= ResourceLibrary.for(path: @path).size
  def calculators = @calculators ||= Calculator.for_path(@path).size
  def terms = @terms ||= GlossaryTerm.for_path(@path).count

  private
    def kinds = @kinds ||= @path.lessons.group(:kind).count
end
