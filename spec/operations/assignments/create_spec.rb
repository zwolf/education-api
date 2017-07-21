require 'spec_helper'

RSpec.describe Assignments::Create do
  let(:current_user) { create :user }
  let(:client) { instance_double(Panoptes::Client) }
  let(:operation) { described_class.with(current_user: current_user, client: client) }
  let(:project) { create :project }
  let(:custom_project) { create(:project, custom_subject_set: true) }
  let(:classroom) { create :classroom, teachers: [current_user] }

  before do
    allow(client).to receive_message_chain(:panoptes, :workflow).and_return("links" => {"project" => "1"})
    allow(client).to receive_message_chain(:panoptes, :create_workflow).and_return("id" => "2", "links" => {"project" => "1"})
    allow(client).to receive_message_chain(:panoptes, :create_subject_set).and_return("id" => "123")
    allow(client).to receive_message_chain(:panoptes, :add_subjects_to_subject_set).and_return(true)
  end

  describe "project uses a custom subject set and workflow" do
    it 'creates a new subject set' do
      expect(client).to receive_message_chain(:panoptes, :create_subject_set).and_return("id" => "123")
      operation.run!  project_id: custom_project.id,
                      attributes: {name: 'foo'},
                      relationships: {classroom: {data: {id: classroom.id, type: 'classrooms'}}}
    end

    it 'clones the workflow' do
      expect(client).to receive_message_chain(:panoptes, :create_workflow)
                      .with("display_name" => an_instance_of(String),
                            "retirement" => {criteria: "never_retire", options: {}},
                            "links" => {project: "1", subject_sets: ["123"]})
                      .and_return("id" => "2")
      operation.run!  project_id: custom_project.id,
                      attributes: {name: 'foo'},
                      relationships: {classroom: {data: {id: classroom.id, type: 'classrooms'}}}
    end
  end

  describe "project uses static workflow and subject sets" do
    it 'does not create a new subject set if false' do
      operation.run!  project_id: project.id,
                      workflow_id: "999",
                      attributes: {name: 'foo'},
                      relationships: {classroom: {data: {id: classroom.id, type: 'classrooms'}}}
      expect(classroom.assignments.first.subject_set_id).to be_nil
    end

    it "raises an error if a workflow is not included" do
      expect {
        operation.run!  project_id: project.id,
                        attributes: {name: 'foo'},
                        relationships: {classroom: {data: {id: classroom.id, type: 'classrooms'}}}
      }.to raise_error ActiveInteraction::InvalidInteractionError
    end

    it "does not create a new workflow" do
      project.update(custom_subject_set: false)
      operation.run!  project_id: project.id,
                      workflow_id: "999",
                      attributes: {name: 'foo'},
                      relationships: {classroom: {data: {id: classroom.id, type: 'classrooms'}}}
      expect(classroom.assignments.first.workflow_id).to eq("999")
    end
  end

  it 'creates an assignment' do
    metadata = { "fake" => "data" }
    assignment = operation.run!   project_id: custom_project.id,
                                  attributes: { name: "foo", metadata: metadata },
                                  relationships: {classroom: {data: {id: classroom.id, type: 'classrooms'}}}
    expect(classroom.assignments.count).to eq(1)
    expect(classroom.assignments.first).to eq(assignment)
    expect(classroom.assignments.first.attributes["metadata"]).to eq(metadata)
  end

  it 'links students' do
    student_user1 = create :student_user, user: create(:user), classroom: classroom
    student_user2 = create :student_user, user: create(:user), classroom: classroom

    assignment = operation.run! project_id: custom_project.id,
                                attributes: {name: 'foo'},
                                relationships: {classroom: {data: {id: classroom.id, type: 'classrooms'}},
                                                student_users: {data: [{id: student_user1.id, type: 'student_user'},
                                                                       {id: student_user2.id, type: 'student_user'}]}}
    expect(assignment.student_users).to match_array([student_user1, student_user2])
  end
end
