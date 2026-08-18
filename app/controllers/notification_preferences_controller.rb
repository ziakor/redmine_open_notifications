# frozen_string_literal: true

class NotificationPreferencesController < ApplicationController
  before_action :require_login

  def show
    redirect_to action: 'edit'
  end

  def edit
    @preference = UserNotificationPreference.find_or_create_by(user_id: User.current.id)
  end

  def update
    @preference = UserNotificationPreference.find_or_create_by(user_id: User.current.id)
    
    p_params = preference_params
    if params[:user_notification_preference] && params[:user_notification_preference][:work_days].is_a?(Array)
      p_params[:work_days] = params[:user_notification_preference][:work_days].reject(&:blank?).join(',')
    end

    if params[:user_notification_preference] && params[:user_notification_preference][:enabled_events].is_a?(Array)
      p_params[:enabled_events] = params[:user_notification_preference][:enabled_events].reject(&:blank?).join(',')
    end

    if @preference.update(p_params)
      flash[:notice] = l(:notice_preferences_updated)
      redirect_to action: 'edit'
    else
      render action: 'edit'
    end
  end

  private

  def preference_params
    params.require(:user_notification_preference).permit(
      :webpush_enabled,
      :enable_sound, :enabled_events,
      :quiet_hours_start, :quiet_hours_end, :work_days,
      :digest_enabled, :digest_frequency
    )
  end
end
