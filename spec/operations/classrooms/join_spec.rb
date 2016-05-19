require 'spec_helper'

RSpec.describe Classrooms::Join do
  let(:current_user) { build :user }
  let(:panoptes) { instance_double(Panoptes::Client, join_user_group: true) }
  let(:classroom) { create :classroom }

  it 'joins a student to a classroom' do
    described_class.run! current_user: current_user, panoptes: panoptes,
      id: classroom.id, join_token: classroom.join_token
    expect(classroom.students(true)).to include(current_user)
  end
end
