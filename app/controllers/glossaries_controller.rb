class GlossariesController < ApplicationController
  allow_unauthenticated_access

  def show
    @groups = Glossary.grouped
  end
end
