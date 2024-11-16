class MembershipPolicy < ApplicationPolicy
  def index?
    true
  end

  def new?
    create?
  end

  def create?
    p "User is admin #{membership&.admin?}"
    membership&.admin?
  end

  def edit?
    update?
  end

  def update?
    membership&.admin?
  end

  def destroy?
    membership&.admin? || record.user == user
  end

  private

  def membership
    p "user value #{user.inspect}"
    p "000000000000000000000 record #{record.organization.memberships.find_by(user_id: user.user_id)}"
    record.organization.memberships.find_by(user_id: user.user_id)
  end
end
