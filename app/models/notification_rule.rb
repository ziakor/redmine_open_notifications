class NotificationRule < ActiveRecord::Base
  belongs_to :project, optional: true

  serialize :events, Array
  serialize :conditions, Hash

  scope :for_project, ->(project_id) { where(project_id: [project_id, nil]).where(active: true) }
end
