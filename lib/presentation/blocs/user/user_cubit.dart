import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain/entities/user.dart';
import '../../../domain/repositories/user_repository.dart';

// ── State ──────────────────────────────────────────────────────────────────

abstract class UserState extends Equatable {
  const UserState();
  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {
  const UserInitial();
}

class UserLoading extends UserState {
  const UserLoading();
}

class UsersLoaded extends UserState {
  final List<User> users;
  final User? activeUser;
  const UsersLoaded({required this.users, this.activeUser});
  @override
  List<Object?> get props => [users, activeUser];
}

class UserAuthenticated extends UserState {
  final User user;
  const UserAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class UserError extends UserState {
  final String message;
  const UserError(this.message);
  @override
  List<Object?> get props => [message];
}

class UserPinError extends UserState {
  final int attemptsLeft;
  const UserPinError({required this.attemptsLeft});
  @override
  List<Object?> get props => [attemptsLeft];
}

// ── Cubit ──────────────────────────────────────────────────────────────────

class UserCubit extends Cubit<UserState> {
  final IUserRepository _repository;
  int _failedAttempts = 0;

  UserCubit({required IUserRepository repository})
      : _repository = repository,
        super(const UserInitial());

  // ── Kullanıcı Listesi ─────────────────────────────────────────────────────

  Future<void> loadUsers() async {
    emit(const UserLoading());
    final usersResult = await _repository.getAllUsers();
    final activeResult = await _repository.getActiveUser();

    usersResult.fold(
      (failure) => emit(UserError(failure.message)),
      (users) {
        final activeUser = activeResult.fold((_) => null, (u) => u);
        // Aktif kullanıcı varsa otomatik olarak authenticate et
        // (her oturum açılışında PIN girişi gerekmez)
        if (activeUser != null) {
          emit(UserAuthenticated(activeUser));
        } else {
          emit(UsersLoaded(users: users, activeUser: null));
        }
      },
    );
  }

  // ── Profil Seçme & PIN Doğrulama ──────────────────────────────────────────

  Future<void> selectUser(String userId, String pin) async {
    emit(const UserLoading());

    final verifyResult = await _repository.verifyPin(userId, pin);
    final isValid = verifyResult.fold((_) => false, (v) => v);

    if (!isValid) {
      _failedAttempts++;
      const maxAttempts = 5;
      emit(UserPinError(attemptsLeft: maxAttempts - _failedAttempts));
      return;
    }

    _failedAttempts = 0;
    await _repository.setActiveUser(userId);

    final userResult = await _repository.getUserById(userId);
    userResult.fold(
      (failure) => emit(UserError(failure.message)),
      (user) => emit(UserAuthenticated(user)),
    );
  }

  // ── Profil Yönetimi ───────────────────────────────────────────────────────

  Future<void> createUser(User user) async {
    final result = await _repository.createUser(user);
    await result.fold(
      (failure) async => emit(UserError(failure.message)),
      (createdUser) async {
        // İlk kullanıcı oluşturulduğunda otomatik olarak oturum aç
        final usersResult = await _repository.getAllUsers();
        final userCount = usersResult.fold((_) => 0, (u) => u.length);
        if (userCount == 1) {
          await _repository.setActiveUser(createdUser.id);
          emit(UserAuthenticated(createdUser));
        } else {
          await loadUsers();
        }
      },
    );
  }

  Future<void> updateUser(User user) async {
    final result = await _repository.updateUser(user);
    result.fold(
      (failure) => emit(UserError(failure.message)),
      (_) => loadUsers(),
    );
  }

  Future<void> deleteUser(String userId) async {
    final result = await _repository.deleteUser(userId);
    result.fold(
      (failure) => emit(UserError(failure.message)),
      (_) => loadUsers(),
    );
  }

  // ── Oturum Kapatma ────────────────────────────────────────────────────────

  Future<void> logout() async {
    emit(const UserLoading());
    // Aktif kullanıcıyı temizle (boş ID = oturum yok)
    await _repository.setActiveUser('');
    final usersResult = await _repository.getAllUsers();
    usersResult.fold(
      (failure) => emit(UserError(failure.message)),
      (users) => emit(UsersLoaded(users: users, activeUser: null)),
    );
  }
}
