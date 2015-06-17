class Function < ActiveRecord::Base
  unloadable
  acts_as_list

  attr_accessible :name, :position, :authorized_viewers

  has_many :member_functions, :dependent => :destroy
  has_many :members, :through => :member_functions

  has_many :project_functions, :dependent => :destroy
  has_many :projects, :through => :project_functions

  after_create :set_own_visibility,
               :if => Proc.new { |_| Function.column_names.include?("authorized_viewers") }

  validates_presence_of :name

  scope :sorted, lambda { order("#{table_name}.position ASC") }
  scope :active_by_default, -> { where("active_by_default = ?", TRUE) }

  def self.available_functions_for(project)
    functions = Function.joins(:project_functions).where("project_id = ?", project.id).sorted if project.present?
    if functions == nil || functions.blank?
      functions = Function.active_by_default.sorted
    end
    functions
  end

  def authorized_viewer_ids
    "#{authorized_viewers}".split("|").reject(&:blank?).map(&:to_i)
  end

  def to_s
    name
  end

  def allowed_to?(action)
    true # TODO Remove this method without breaking issues search
  end

  def users_by_project(project)
    User.joins(:members => :member_functions).where("function_id = ? AND project_id = ?", self.id, project.id).active.order("lastname ASC")
  end

  private

    def set_own_visibility
      reload
      if !authorized_viewers.present? || !authorized_viewers.split('|').include?(self.id)
        update_attribute(:authorized_viewers, "#{authorized_viewers.present? ? authorized_viewers : "|"}#{self.id}|")
      end
    end
end
