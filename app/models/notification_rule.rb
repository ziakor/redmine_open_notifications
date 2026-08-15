class NotificationRule < ActiveRecord::Base
  belongs_to :project, optional: true

  if ActiveRecord::VERSION::STRING >= '7.1'
    serialize :events, type: Array
    serialize :conditions, type: Hash
  else
    serialize :events, Array
    serialize :conditions, Hash
  end

  scope :for_project, ->(project_id) { where(project_id: [project_id, nil]).where(active: true) }
end
