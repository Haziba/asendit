require 'rails_helper'

RSpec.describe RouteSetsController, type: :controller do
  let(:place) { create(:place, :with_grades) }
  let(:admin) { false }
  let(:user) { create(:user, admin: admin, place: place) }

  before { allow(controller).to receive(:session).and_return(userinfo: { 'id' => user.id, 'token' => user.token }) }

  describe 'POST #create' do
    context 'as an admin' do
      let(:admin) { true }

      it 'creates a new route set and redirects to edit path' do
        post :create, params: { grade: place.grades.first.id, added: '2023-08-08', place_id: place.id }

        route_set = RouteSet.last
        expect(route_set.grade).to eq(place.grades.first)
        expect(route_set.added.to_s).to eq('2023-08-08 00:00:00 UTC')
        expect(response).to redirect_to(edit_route_set_path(route_set.id))
      end
    end

    context 'as a non-admin' do
      it 'does not allow creating a route set and redirects to index' do
        post :create, params: { colour: 'red', added: '2023-08-08', place_id: place.id }

        expect(RouteSet.where(grade: place.grades.find_by(name: 'red'), added: '2023-08-08').first).to be_nil
        expect(response).to redirect_to(route_sets_path)
      end
    end
  end

  describe 'GET #edit' do
    let!(:route_set) { create(:route_set) }

    context 'as an admin' do
      let(:admin) { true }

      it 'assigns the requested route set to @route_set' do
        get :edit, params: { id: route_set.id }
        expect(assigns(:route_set)).to eq(route_set)
      end
    end

    context 'as a non-admin' do
      let(:admin) { false }

      it 'redirects to index' do
        get :edit, params: { id: route_set.id }
        expect(response).to redirect_to(route_sets_path)
      end
    end
  end

  describe 'GET #index' do
    let!(:route_set1) { create(:route_set, added: 3.day.ago, grade: user.place.grades.first, place: user.place) }
    let!(:route_set2) { create(:route_set, added: 2.days.ago, grade: user.place.grades.first, place: user.place) }
    let!(:route_set3) { create(:route_set, added: 1.days.ago, grade: user.place.grades.last, place: user.place) }
    let!(:other_place_route_set) { create(:route_set, added: 1.days.ago, grade: create(:grade), place: create(:place)) }
    let!(:admin) { false }

    it 'assigns active and old route sets' do
      get :index

      expect(assigns(:active_route_sets).map(&:id)).to match_array([route_set2, route_set3].map(&:id))
      expect(assigns(:old_route_sets).map(&:id)).to eq([route_set1].map(&:id))
    end
  end

  describe 'GET #show' do
    let!(:route_set) { create(:route_set) }
    let!(:route1) { create(:route, route_set: route_set) }
    let!(:route2) { create(:route, route_set: route_set) }
    let!(:climb) { create(:climb, user: user, route_state_json: [{ "route_id" => route1.id, "status" => "sent" }]) }
    let!(:admin) { false }

    before do
      get :show, params: { id: route_set.id }
    end

    it 'assigns the requested route set to @route_set' do
      expect(assigns(:route_set)).to eq(route_set)
    end

    it 'assigns the climbed routes to @climbed_routes' do
      expect(assigns(:climbed_routes)).to eq([route1])
    end
  end

  describe 'DELETE #destroy' do
    let!(:route_set) { create(:route_set) }

    context 'as an admin' do
      let(:admin) { true }

      it 'destroys the route set and redirects to index' do
        expect {
          delete :destroy, params: { id: route_set.id }
        }.to change(RouteSet, :count).by(-1)

        expect(response).to redirect_to(route_sets_path)
      end
    end

    context 'as a non-admin' do
      let(:admin) { false }

      before do
        route_set.place.update(user: create(:user))
      end

      it 'does not destroy the route set and redirects to index' do
        expect {
          delete :destroy, params: { id: route_set.id }
        }.not_to change(RouteSet, :count)

        expect(response).to redirect_to(route_sets_path)
      end
    end
  end
end
