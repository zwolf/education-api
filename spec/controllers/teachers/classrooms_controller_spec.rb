require 'rails_helper'

RSpec.describe Teachers::ClassroomsController do
  let(:client) do
    double(Panoptes::Client, me: {"id" => "1", "login" => "login", "display_name" => "display_name"}).tap do |client|
      allow(client).to receive(:is_a?).and_return(false)
      allow(client).to receive(:is_a?).with(Panoptes::Client).and_return(true)
    end
  end

  let(:parsed_response) do
    JSON.parse(response.body)
  end

  before do
    allow(controller).to receive(:panoptes).and_return(client)
  end

  describe "GET index" do
    it "returns an empty list if there are no classrooms" do
      request.headers["Authorization"] = "Bearer xyz"
      allow(client).to receive(:paginate).with("/user_groups", {}).and_return("user_groups" => [])
      get :index, format: :json
      expect(parsed_response).to eq("data" => [])
    end

    it 'returns the classrooms with students' do
      classroom = Classroom.create! name: 'Foo', zooniverse_group_id: 'asdf', join_token: 'abc'
      student   = classroom.students.create! zooniverse_id: 'zoo1'

      request.headers["Authorization"] = "Bearer xyz"
      allow(client).to receive(:paginate).with("/user_groups", {}).and_return("user_groups" => [{"id" => classroom.zooniverse_group_id}])
      get :index, format: :json
      expect(response.body).to eq(ActiveModel::SerializableResource.new([classroom], include: [:students]).to_json)
    end
  end

  describe "POST create" do
    it "creates a new classroom" do
      request.headers["Authorization"] = "Bearer xyz"
      created_user_group = {'id' => 1, 'join_token' => 'asdf'}
      allow(client).to receive(:post).with("/user_groups", user_groups: {name: an_instance_of(String)}).and_return("user_groups" => [created_user_group])
      post :create, data: {attributes: {name: "Foo"}}, format: :json

      classroom = Classroom.first
      expect(response.body).to eq(ActiveModel::SerializableResource.new(classroom, include: [:students]).to_json)
    end
  end
end
