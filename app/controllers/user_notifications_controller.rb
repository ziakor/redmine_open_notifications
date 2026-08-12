# frozen_string_literal: true

class UserNotificationsController < ApplicationController
  before_action :require_login

  def index
    @notifications = User.current.user_notifications.active.order(created_at: :desc).limit(50)
    respond_to do |format|
      format.html
      format.json { render json: @notifications }
    end
  end

  def update
    notification = User.current.user_notifications.find(params[:id])
    notification.update(read_at: Time.current)
    respond_to do |format|
      format.html { redirect_to user_notifications_path, notice: "Notification marquée comme lue." }
      format.json { render json: { status: 'success' } }
    end
  end

  def destroy
    notification = User.current.user_notifications.find(params[:id])
    notification.destroy
    respond_to do |format|
      format.html { redirect_to user_notifications_path, notice: "Notification supprimée." }
      format.json { render json: { status: 'success' } }
    end
  end

  def read_all
    User.current.user_notifications.unread.update_all(read_at: Time.current)
    respond_to do |format|
      format.html { redirect_to user_notifications_path, notice: "Toutes les notifications ont été marquées comme lues." }
      format.json { render json: { status: 'success' } }
    end
  end

  def clear_all
    User.current.user_notifications.destroy_all
    respond_to do |format|
      format.html { redirect_to user_notifications_path, notice: "Toutes les notifications ont été supprimées." }
      format.json { render json: { status: 'success' } }
    end
  end

  def snooze
    notification = User.current.user_notifications.find(params[:id])
    duration = (params[:hours] || 2).to_i.hours
    notification.update(snoozed_until: Time.current + duration)
    respond_to do |format|
      format.html { redirect_to user_notifications_path, notice: "Notification suspendue pour 2 heures." }
      format.json { render json: { status: 'snoozed', until: notification.snoozed_until } }
    end
  end
end
