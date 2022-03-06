import 'dart:async';

import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:meta/meta.dart';

import '../../../../auth.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginWithEmailUseCase loginWithEmailUseCase;
  final LoginWithGoogleUseCase loginWithGoogleUseCase;

  LoginBloc({
    @required this.loginWithEmailUseCase,
    @required this.loginWithGoogleUseCase,
  })  : assert(loginWithEmailUseCase != null && loginWithGoogleUseCase != null),
        super(const LoginState());

  @override
  Stream<LoginState> mapEventToState(
    LoginEvent event,
  ) async* {
    if (event is LoginEmailChanged) {
      yield _mapEmailChangedToState(event, state);
    } else if (event is LoginPasswordChanged) {
      yield _mapPasswordChangedToState(event, state);
    } else if (event is LoginSubmitted) {
      yield* _mapLoginSubmittedToState(event, state);
    } else if (event is LoginGoogleSubmitted) {
      yield* _mapLoginGoogleSubmittedToState(event, state);
    }
  }

  LoginState _mapEmailChangedToState(
    LoginEmailChanged event,
    LoginState state,
  ) {
    final email = EmailFormZ.dirty(event.email);
    return state.copyWith(
      email: email,
      status: Formz.validate([state.password, email]),
    );
  }

  LoginState _mapPasswordChangedToState(
    LoginPasswordChanged event,
    LoginState state,
  ) {
    final password = PasswordFormZ.dirty(event.password);
    return state.copyWith(
      password: password,
      status: Formz.validate([password, state.email]),
    );
  }

  Stream<LoginState> _mapLoginSubmittedToState(
    LoginSubmitted event,
    LoginState state,
  ) async* {
    if (state.status.isValidated) {
      yield state.copyWith(status: FormzStatus.submissionInProgress);
      try {
        final result = await loginWithEmailUseCase(LoginEmailParams(
            data: LoginEmailBody(
          email: state.email.value,
          password: state.password.value,
        )));

        yield* result.fold((l) async* {
          yield state.copyWith(
            status: FormzStatus.submissionFailure,
            failure: l,
          );
        }, (r) async* {
          yield state.copyWith(status: FormzStatus.submissionSuccess, user: r);
        });
      } on Exception catch (_) {
        yield state.copyWith(status: FormzStatus.submissionFailure);
      }
    }
  }

  Stream<LoginState> _mapLoginGoogleSubmittedToState(
    LoginGoogleSubmitted event,
    LoginState state,
  ) async* {
    yield state.copyWith(status: FormzStatus.submissionInProgress);
    try {
      final result = await loginWithGoogleUseCase(NoParams());

      yield* result.fold((l) async* {
        yield state.copyWith(
          status: FormzStatus.submissionFailure,
          failure: null,
        );
      }, (r) async* {
        yield state.copyWith(
          status: FormzStatus.submissionSuccess,
          user: r,
        );
      });
    } on Exception catch (_) {
      yield state.copyWith(status: FormzStatus.submissionFailure);
    }
  }
}
