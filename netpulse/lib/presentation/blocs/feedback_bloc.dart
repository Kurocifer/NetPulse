import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

abstract class FeedbackEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SubmitFeedback extends FeedbackEvent {
  final int rating;
  final String comment;
  SubmitFeedback(this.rating, this.comment);
  @override
  List<Object?> get props => [rating, comment];
}

abstract class FeedbackState extends Equatable {
  @override
  List<Object?> get props => [];
}

class FeedbackInitial extends FeedbackState {}
class FeedbackSubmitting extends FeedbackState {}
class FeedbackSuccess extends FeedbackState {}
class FeedbackError extends FeedbackState {
  final String error;
  FeedbackError(this.error);
  @override
  List<Object?> get props => [error];
}

class FeedbackBloc extends Bloc<FeedbackEvent, FeedbackState> {
  FeedbackBloc() : super(FeedbackInitial()) {
    on<SubmitFeedback>(_onSubmitFeedback);
  }

  void _onSubmitFeedback(SubmitFeedback event, Emitter<FeedbackState> emit) {
    // Placeholder
  }
}