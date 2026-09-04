class AppFormatters {
	AppFormatters._();

	static const List<String> _months = [
		'Jan',
		'Feb',
		'Mar',
		'Apr',
		'May',
		'Jun',
		'Jul',
		'Aug',
		'Sep',
		'Oct',
		'Nov',
		'Dec',
	];

	static const List<String> _weekdays = [
		'Monday',
		'Tuesday',
		'Wednesday',
		'Thursday',
		'Friday',
		'Saturday',
		'Sunday',
	];

	static String date(DateTime value) {
		return '${_months[value.month - 1]} ${value.day}, ${value.year}';
	}

	static String relativeDate(DateTime value) {
		final now = DateTime.now();
		final today = DateTime(now.year, now.month, now.day);
		final difference = value.difference(today).inDays;
		if (difference == 0) return 'Today';
		if (difference == 1) return 'Tomorrow';
		if (difference == -1) return 'Yesterday';
		return _weekdays[value.weekday - 1];
	}

	static String timeAgo(DateTime value) {
		final difference = DateTime.now().difference(value);
		if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
		if (difference.inHours < 24) return '${difference.inHours}h ago';
		return 'Yesterday';
	}
}
