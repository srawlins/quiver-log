// Copyright 2013 Google Inc. All Rights Reserved.

//
// Licensed under the Apache License, Version 2.0 (the 'License');
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an 'AS IS' BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

part of quiver.log;

/// Appenders define output vectors for logging messages. An appender can be
/// used with multiple [Logger]s, but can use only a single [Formatter]. This
/// class is designed as base class for other Appenders to extend.
///
/// Generally an Appender recieves a log message from the attached logger
/// streams, runs it through the formatter and then outputs it.
abstract class Appender<T> {
  final List<StreamSubscription> _subscriptions = [];
  final Formatter<T> formatter;

  Appender(this.formatter);

  //TODO(bendera): What if we just handed in the stream? Does it need to be a
  //Logger or just a stream of LogRecords?

  /// Attaches a logger to this appender
  void attachLogger(Logger logger) {
    _subscriptions.add(logger.onRecord.listen((LogRecord r) {
      try {
        append(r, formatter);
      } catch (e) {
        //will keep the logger from downing the app, how best to notify the
        //app here?
      }
    }));
  }

  /// Each appender should implement this method to perform custom log output.
  void append(LogRecord record, Formatter<T> formatter);

  /// Terminate this Appender and cancel all logging subscriptions.
  void stop() => _subscriptions.forEach((s) => s.cancel());
}

/// Interface defining log formatter.
abstract class Formatter<T> {
  /// Returns a message of type T based on provided [LogRecord].
  T call(LogRecord record);
}

/// Formatter accepts a [LogRecord] and returns a T
abstract class FormatterBase<T> extends Formatter<T> {
  /// Formats a given [LogRecord] returning type T as a result
  T call(LogRecord record);
}

/// Formats log messages using a simple pattern
class BasicLogFormatter implements FormatterBase<String> {
  static final DateFormat _dateFormat = new DateFormat('yyMMdd HH:mm:ss.S');

  const BasicLogFormatter();

  /// Formats a [LogRecord] using the following pattern:
  ///
  /// MMyy HH:MM:ss.S level sequence loggerName message
  String call(LogRecord record) {
    var message = '${_dateFormat.format(record.time)} '
        '${record.level} '
        '${record.sequenceNumber} '
        '${record.loggerName} '
        '${record.message}';
    if (record.error != null) {
      message = '$message, error: ${record.error}';
    }
    if (record.stackTrace!= null) {
      message = '$message, stackTrace: ${record.stackTrace}';
    }
    return message;
  }
}

/// Default instance of the BasicLogFormatter
const BASIC_LOG_FORMATTER = const BasicLogFormatter();

/// Appends string messages to the console using print function
class PrintAppender extends Appender<String> {

  /// Returns a new ConsoleAppender with the given [Formatter<String>]
  PrintAppender(Formatter<String> formatter) : super(formatter);

  @override
  void append(LogRecord record, Formatter<String> formatter) {
    print(formatter.call(record));
  }
}

/// Appends string messages to the messages list. Note that this logger does not
/// ever truncate so only use for diagnostics or short lived applications.
class InMemoryListAppender extends Appender<Object> {
  final List<Object> messages = [];

  /// Returns a new InMemoryListAppender with the given [Formatter<String>]
  InMemoryListAppender(Formatter<Object> formatter) : super(formatter);

  @override
  void append(LogRecord record, Formatter<Object> formatter) {
    messages.add(formatter.call(record));
  }
}
