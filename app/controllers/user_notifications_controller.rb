# frozen_string_literal: true

class UserNotificationsController < ApplicationController
  before_action :require_login

  def index
    @notifications = User.current.user_notifications.active.order(created_at: :desc).limit(50)
    respond_to do |format|
      format.html
      format.json { render json: @notifications.as_json(methods: [:target_url]) }
    end
  end

  def update
    notification = User.current.user_notifications.find(params[:id])
    notification.update(read_at: Time.current)
    respond_to do |format|
      format.html { redirect_to user_notifications_path, notice: l(:notice_notification_marked_read) }
      format.json { render json: { status: 'success' } }
    end
  end

  def destroy
    notification = User.current.user_notifications.find(params[:id])
    notification.destroy
    respond_to do |format|
      format.html { redirect_to user_notifications_path, notice: l(:notice_notification_deleted) }
      format.json { render json: { status: 'success' } }
    end
  end

  def read_all
    User.current.user_notifications.unread.update_all(read_at: Time.current)
    respond_to do |format|
      format.html { redirect_to user_notifications_path, notice: l(:notice_all_notifications_marked_read) }
      format.json { render json: { status: 'success' } }
    end
  end

  def clear_all
    User.current.user_notifications.destroy_all
    respond_to do |format|
      format.html { redirect_to user_notifications_path, notice: l(:notice_all_notifications_deleted) }
      format.json { render json: { status: 'success' } }
    end
  end

  def snooze
    notification = User.current.user_notifications.find(params[:id])
    hours = (params[:hours] || 2).to_i
    notification.update(snoozed_until: Time.current + hours.hours)
    respond_to do |format|
      format.html { redirect_to user_notifications_path, notice: l(:notice_notification_snoozed, count: hours) }
      format.json { render json: { status: 'snoozed', until: notification.snoozed_until } }
    end
  end
end
