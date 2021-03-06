class Assignment < ActiveRecord::Base
  include Deletable

  belongs_to :classroom

  has_many :student_assignments
  has_many :student_users, through: :student_assignments

  validates :classroom, presence: true
  validates :workflow_id, presence: true
end
