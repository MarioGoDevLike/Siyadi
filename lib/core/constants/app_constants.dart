/// App-wide string and routing constants for SIYADI.
abstract final class AppConstants {
  static const String appName = 'SIYADI';
  static const String appTagline = 'The hunting community';

  static const String defaultCountry = 'Lebanon';

  static const List<String> lebanonRegions = [
    'Beirut',
    'Mount Lebanon',
    'North',
    'Akkar',
    'South',
    'Nabatieh',
    'Bekaa',
    'Baalbek-Hermel',
  ];
}

abstract final class AppRoutes {
  static const String splash = '/';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String map = '/map';
  static const String marketplace = '/marketplace';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String createPost = '/create/post';
  static const String createFieldReport = '/create/field-report';
  static const String fieldReports = '/field-reports';
  static const String messages = '/messages';
  static const String notifications = '/notifications';
  static const String proposeLocation = '/map/propose';
  static const String myLocationProposals = '/map/proposals';

  static String userProfile(String uid) => '/u/$uid';
  static String userFollowers(String uid) => '/u/$uid/followers';
  static String userFollowing(String uid) => '/u/$uid/following';
  static String postComments(String postId) => '/posts/$postId/comments';
  static String chat(String conversationId) => '/messages/$conversationId';
  static String locationDetail(String id) => '/map/location/$id';
}
