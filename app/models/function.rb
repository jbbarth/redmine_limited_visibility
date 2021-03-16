class Function < ActiveRecord::Base
  include Redmine::SafeAttributes

  unloadable
  acts_as_positioned

  safe_attributes :name, :position, :authorized_viewers, :move_to, :hidden_on_overview, :active_by_default, :see_all_issues, :description

  has_many :member_functions, :dependent => :destroy
  has_many :members, :through => :member_functions

  has_many :project_functions, :dependent => :destroy
  has_many :projects, :through => :project_functions

  after_create :set_own_visibility,
               :if => Proc.new { |_| Function.column_names.include?("authorized_viewers") }

  validates_presence_of :name
  validates_length_of :name, maximum: 40

  scope :sorted, lambda { order("#{table_name}.position ASC") }
  scope :active_by_default, -> { where("active_by_default = ?", true) }

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

  def users_by_project_and_organization(project, organization)
    User.joins(:members => :member_functions)
        .where("function_id = ?", self.id)
        .where("project_id = ?", project.id)
        .where("organization_id = ?", organization.id)
        .active.order("lastname ASC")
  end

  def self.functions_from_authorized_viewers(authorized_viewers)
    Function.where(:id => "#{authorized_viewers}".split("|")).sorted
  end

  def is_activated?(project:)
    project.functions.present? ? project.functions.include?(self) : self.active_by_default
  end

  def update_private_notes_group(functions_ids)
    grouped_functions = [self] | Function.where(id: functions_ids)
    grouped_functions.each do |group|
      PrivateNotesGroup.where(group_id: group.id).where("function_id NOT IN (?)", grouped_functions.map(&:id)).delete_all
      (grouped_functions - [group]).each do |f|
        PrivateNotesGroup.find_or_create_by(group_id: group.id, function_id: f.id)
      end
    end
  end

  private

  def set_own_visibility
    reload
    if !authorized_viewers.present? || !authorized_viewers.split('|').include?(self.id)
      update_attribute(:authorized_viewers, "#{authorized_viewers.present? ? authorized_viewers : "|"}#{self.id}|")
    end
  end

  def self.all_functions_for(project)
    members = project.memberships
    all_function = []
    members.each do |member|      
      functions = member.functions.to_a
      functions.each do |function|
        all_function.push(function)
      end
    end    
    (all_function + available_functions_for(project).to_a).uniq
  end

end
