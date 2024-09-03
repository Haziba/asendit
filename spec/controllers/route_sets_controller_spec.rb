require 'rails_helper'

RSpec.describe RouteSetsController, type: :controller do
  let(:place) { create(:place) }
  let(:user) { create(:user) }
  let(:admin_user) { { "id" => user.reference, "admin" => true } }
  let(:non_admin_user) { { "id" => user.reference, "admin" => false } }

  describe 'POST #create' do
    context 'as an admin' do
      before { allow(controller).to receive(:session).and_return(userinfo: admin_user) }

      it 'creates a new route set and redirects to edit path' do
        post :create, params: { colour: place.colour_sets.first.colours.first.id.to_s, added: '2023-08-08', place_id: place.id }

        route_set = RouteSet.last
        expect(route_set.route_set_colour_set_colour).to eq(place.colour_sets.first.colours.first)
        expect(route_set.added.to_s).to eq('2023-08-08 00:00:00 UTC')
        expect(response).to redirect_to(edit_route_set_path(route_set.id))
      end
    end

    context 'as a non-admin' do
      before { allow(controller).to receive(:session).and_return(userinfo: non_admin_user) }

      it 'does not allow creating a route set and redirects to index' do
        post :create, params: { colour: 'red', added: '2023-08-08', place_id: place.id }

        expect(RouteSet.count).to eq(0)
        expect(response).to redirect_to(route_sets_path)
      end
    end
  end

  describe 'GET #edit' do
    let!(:route_set) { create(:route_set) }

    context 'as an admin' do
      before { allow(controller).to receive(:session).and_return(userinfo: admin_user) }

      it 'assigns the requested route set to @route_set' do
        get :edit, params: { id: route_set.id }
        expect(assigns(:route_set)).to eq(route_set)
      end
    end

    context 'as a non-admin' do
      before { allow(controller).to receive(:session).and_return(userinfo: non_admin_user) }

      it 'redirects to index' do
        get :edit, params: { id: route_set.id }
        expect(response).to redirect_to(route_sets_path)
      end
    end
  end

  describe 'GET #index' do
    let!(:route_set1) { create(:route_set, added: 3.day.ago, color: 'red', place: user.place) }
    let!(:route_set2) { create(:route_set, added: 2.days.ago, color: 'red', place: user.place) }
    let!(:route_set3) { create(:route_set, added: 1.days.ago, color: 'blue', place: user.place) }
    let!(:other_place_route_set) { create(:route_set, added: 1.days.ago, color: 'blue', place: create(:place)) }

    before { allow(controller).to receive(:session).and_return(userinfo: non_admin_user) }

    it 'assigns active and old route sets' do
      get :index

      expect(assigns(:active_route_sets)).to match_array([route_set2, route_set3])
      expect(assigns(:old_route_sets)).to eq([route_set1])
    end
  end

  describe 'GET #show' do
    let!(:route_set) { create(:route_set) }
    let!(:route1) { create(:route, route_set: route_set) }
    let!(:route2) { create(:route, route_set: route_set) }
    let!(:climb) { create(:climb, climber: user.reference, route_state_json: [{ "route_id" => route1.id, "status" => "sent" }]) }

    before do
      allow(controller).to receive(:session).and_return(userinfo: non_admin_user)
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
      before { allow(controller).to receive(:session).and_return(userinfo: admin_user) }

      it 'destroys the route set and redirects to index' do
        expect {
          delete :destroy, params: { id: route_set.id }
        }.to change(RouteSet, :count).by(-1)

        expect(response).to redirect_to(route_sets_path)
      end
    end

    context 'as a non-admin' do
      before { allow(controller).to receive(:session).and_return(userinfo: non_admin_user) }

      it 'does not destroy the route set and redirects to index' do
        expect {
          delete :destroy, params: { id: route_set.id }
        }.not_to change(RouteSet, :count)

        expect(response).to redirect_to(route_sets_path)
      end
    end
  end
end
