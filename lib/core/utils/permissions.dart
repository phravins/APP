import '../../shared/models/models.dart';
import '../errors/failures.dart';

abstract final class Permissions {
  static bool manage(User user, String org) =>
      [Role.owner, Role.admin].contains(user.roleIn(org));
  static bool owner(User user, String org) => user.roleIn(org) == Role.owner;
  static bool view(User user, DueItem item) =>
      manage(user, item.organisationId) ||
      (user.roleIn(item.organisationId) == Role.member &&
          item.assignedToUserId == user.id);
  static bool update(User user, DueItem item) =>
      view(user, item) && !item.isClosed;
  static void require(bool allowed) {
    if (!allowed) throw const PermissionFailure();
  }
}
