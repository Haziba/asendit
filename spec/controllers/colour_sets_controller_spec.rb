require 'rails_helper'

RSpec.describe ColourSetsController, type: :controller do
  let(:place) { create(:place) }

  describe "GET #new" do
    it "returns a successful response" do
      get :new, params: { place_id: place.id }
      new_colour_set = RouteSetColourSet.last
      expect(response).to redirect_to(edit_place_colour_set_path(id: new_colour_set.id))
    end
  end

  describe "GET #edit" do
    let(:colour_set) { create(:route_set_colour_set) }

    it "returns a successful response" do
      get :edit, params: { id: colour_set.id, place_id: place.id }
      expect(response).to be_successful
    end
  end

  describe "PATCH #update" do
    let(:colour_set) { create(:route_set_colour_set) }

    it "updates the colour set" do
      patch :update, params: { id: colour_set.id, place_id: place.id, route_set_colour_set: { description: "Updated Colour Set" } }
      colour_set.reload
      expect(colour_set.description).to eq("Updated Colour Set")
    end

    it "returns errors when update fails" do
      patch :update, params: { id: colour_set.id, place_id: place.id, route_set_colour_set: { description: nil } }
      expect(assigns(:errors)).not_to be_empty
    end
  end

  describe "DELETE #destroy" do
    let(:colour_set) { create(:route_set_colour_set) }

    it "destroys the colour set" do
      delete :destroy, params: { id: colour_set.id, place_id: place.id }
      colour_set.reload
      expect(colour_set.deleted).to be_truthy
    end
  end
end