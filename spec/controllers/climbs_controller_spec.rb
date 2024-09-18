require 'rails_helper'

RSpec.describe ClimbsController, type: :controller do
  let!(:user) { create(:user) }
  let!(:another_user) { create(:user) }

  before do
    allow(controller).to receive(:session).and_return(userinfo: {'id' => user.id, 'token' => user.token})
  end

  describe 'POST #create' do
    context 'when a current climb already exists' do
      let!(:current_climb) { create(:climb, user: user, current: true) }

      it 'redirects to the edit path of the existing climb' do
        post :create
        expect(response).to redirect_to(edit_climb_path(current_climb))
      end
    end

    context 'when no current climb exists' do
      let!(:place) { create(:place) }
      let!(:other_place) { create(:place)}

      let!(:active_route_set) { create(:route_set, added: Date.today, grade: place.grades.first, place: place) }
      let!(:active_older_route_set) { create(:route_set, added: Date.yesterday, grade: place.grades.first, place: place) }
      let!(:active_other_place_route_set) { create(:route_set, grade: other_place.grades.first, place: other_place) }

      before do
        user.update(place: place)

        active_route_set.save!
        active_older_route_set.save!
        active_other_place_route_set.save!
      end

      it 'creates a new climb and redirects to its edit path' do
        expect {
          post :create
        }.to change(Climb, :count).by(1)

        climb = Climb.last
        expect(climb.current).to be true
        expect(climb.route_sets).to eq([active_route_set])
        expect(response).to redirect_to(edit_climb_path(climb))
      end
    end
  end

  describe 'GET #show' do
    let!(:climb) { create(:climb, user: user) }

    it 'assigns the requested climb to @climb' do
      get :show, params: { id: climb.id }
      expect(assigns(:climb)).to eq(climb)
    end

    it 'assigns the climbed routes and route sets' do
      get :show, params: { id: climb.id }
      expect(assigns(:routes)).not_to be_nil
      expect(assigns(:route_sets)).not_to be_nil
    end
  end

  describe 'GET #current' do
    context 'when a current climb exists' do
      let!(:current_climb) { create(:climb, user: user, current: true) }

      it 'redirects to the edit path of the current climb' do
        get :current
        expect(response).to redirect_to(edit_climb_path(current_climb.id))
      end
    end

    context 'when no current climb exists' do
      it 'redirects to the index path' do
        get :current
        expect(response).to redirect_to(climbs_path)
      end
    end
  end

  describe 'GET #edit' do
    let!(:place) { create(:place) }
    let!(:added_route_set) { create(:route_set, grade: place.grades.first, place: place) }
    let!(:first_route_set_for_grade) { create(:route_set, grade: place.grades.last, place: place) }
    let!(:climb) { create(:climb, user: user, route_sets: [added_route_set]) }

    before do
      user.update(place: place)
    end

    it 'assigns the requested climb to @climb' do
      get :edit, params: { id: climb.id }
      expect(assigns(:climb)).to eq(climb)
    end

    it 'assigns the active route sets and routes' do
      get :edit, params: { id: climb.id }
      expect(assigns(:active_route_sets)).not_to be_nil
      expect(assigns(:routes)).not_to be_nil
    end

    it 'adds new route sets if the grade wasnt previously included' do
      get :edit, params: { id: climb.id }
      climb.reload
      expect(climb.route_sets.map(&:id)).to match_array([added_route_set.id, first_route_set_for_grade.id])
    end
  end

  describe 'PATCH #update' do
    let!(:climb) { create(:climb, user: user) }

    it 'updates the climb and redirects to the edit path' do
      patch :update, params: { 'id' => climb.id, 'climbed_at' => '2023-08-08', 'route_states[0][routeId]' => 1, 'route_states[0][status]' => 'flashed' }
      climb.reload
      expect(climb.climbed_at.to_s).to eq('2023-08-08')
      expect(climb.route_state_json).to eq([{"route_id"=>1, "status"=>"flashed"}])
    end
  end

  describe 'PATCH #complete' do
    let!(:climb) { create(:climb, user: user, current: true) }

    it 'marks the climb as complete and redirects to the climb show path' do
      patch :complete, params: { climb_id: climb.id }
      climb.reload
      expect(climb.current).to be false
      expect(response).to redirect_to(climb_path(climb))
    end
  end

  describe 'GET #index' do
    let!(:climb) { create(:climb, user: user) }

    it 'assigns the climbs of the current user to @climbs' do
      get :index
      expect(assigns(:climbs).map(&:id)).to match_array(Climb.where(user: user).map(&:id))
    end
  end

  describe 'DELETE #destroy' do
    let!(:climb) { create(:climb, user: user) }

    it 'deletes the climb and redirects to the climbs path' do
      expect {
        delete :destroy, params: { id: climb.id }
      }.to change(Climb, :count).by(-1)

      expect(response).to redirect_to(climbs_path)
    end
  end

  describe 'before_action :check_auth' do
    context 'when the user is not the owner of the climb' do
      let!(:climb) { create(:climb, user: another_user) }

      it 'redirects to the climbs path' do
        patch :update, params: { id: climb.id, climbed_at: '2023-08-08', route_states: {} }
        expect(response).to redirect_to(climbs_path)
      end
    end

    context 'when the user is the owner of the climb' do
      let!(:climb) { create(:climb, user: user) }

      it 'allows the action to proceed' do
        patch :update, params: { id: climb.id, climbed_at: '2023-08-08', 'route_states[0][routeId]' => 1, 'route_states[0][status]' => 'flashed' }
        expect(response).not_to redirect_to(climbs_path)
      end
    end
  end
end
