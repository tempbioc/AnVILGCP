.gcloud_do <-
    function(...)
{
    .gcloud_sdk_do("gcloud", c(...))
}

#' @importFrom httr POST content_type content
.gcloud_access_token_new <-
    function(app_default, now)
{
    ## obtain the access token
    token <- .gcloud_do("auth", app_default, "print-access-token")

    ## There is only one token per service account, so requesting a
    ## token may return one with expiration less than 60 minutes. So
    ## check the actual expiry time of the token.
    ##
    ## Calculating expiry from before the call (`now` argument) is
    ## conservative -- we underestimate the time by the latency
    ## involved in the POST and result parsing.
    response <- POST(
        "https://www.googleapis.com/oauth2/v1/tokeninfo",
        content_type("application/x-www-form-urlencoded"),
        body = paste0("access_token=", token)
    )
    avstop_for_status(response, ".gcloud_access_token_expires")
    expires <- now + content(response)$expires_in

    list(token = token, expires = expires)
}

#' @rdname gcloud
#'
#' @name gcloud
#'
#' @title gcloud command line utility interface
#'
#' @description These functions invoke the `gcloud` command line
#'     utility. See \link{gsutil} for details on how `gcloud` is
#'     located.
NULL


#' @name gcloud_access_token
#'
#' @title Obtain an access token for a service account
#'
#' @param service character(1) The name of the service, e.g. "terra" for which
#'   to obtain an access token for.
#'
#' @description `gcloud_access_token()` generates a token for the given service
#'   account. The token is cached for the duration of its validity. The token is
#'   refreshed when it expires. The token is obtained using the `gcloud` command
#'   line utility for the given `gcloud_account()`. The function is mainly used
#'   internally by API service functions, e.g., `AnVIL::Terra()`
#'
#' @return `gcloud_access_token()` returns a simple token string to be used with
#'   the given service.
#'
#' @examples
#' library(AnVILBase)
#' if (gcloud_exists() && identical(avplatform_namespace(), "AnVILGCP"))
#'     gcloud_access_token("rawls") |> httr2::obfuscate()
#'
#' @export
gcloud_access_token <- local({
    tokens <- new.env(parent = emptyenv())
    function(service) {
        app_default <-
            if (identical(Sys.getenv("USER"), "jupyter-user"))
                "application-default"

        key <- paste0(service, ":", app_default, ":", gcloud_account())
        now <- Sys.time()
        if (is.null(tokens[[key]])) {
            tokens[[key]] <- .gcloud_access_token_new(app_default, now)
        } else {
            expires_in <- tokens[[key]]$expires - now
            if (expires_in < 1L) {
                ## allow a nearly expired token to fully expire
                if (expires_in > 0L)
                    Sys.sleep(expires_in)
                tokens[[key]] <- .gcloud_access_token_new(app_default, now)
            }
        }

        tokens[[key]]$token
    }
})

#' @rdname gcloud
#'
#' @description `gcloud_exists()` tests whether the `gcloud()` command
#'     can be found on this system. See 'Details' section of `gsutil`
#'     for where the application is searched.
#'
#' @return `gcloud_exists()` returns `TRUE` when the `gcloud`
#'     application can be found, FALSE otherwise.
#'
#' @examples
#' gcloud_exists()
#'
#' @export
gcloud_exists <-
    function()
{
    result <- tryCatch({
        .gcloud_sdk_find_binary("gcloud")
    }, error = function(...) "")
    nchar(result) > 0L
}

#' @importFrom utils tail
.gcloud_get_value_check <-
    function(result, function_name)
{
    value <- tail(result, 1L)
    if (identical(value, "(unset)")) {
        message <- paste0(
            "'", function_name, "()' returned '(unset)'; this may indicate ",
            "that the gcloud active configuration is incorrect. Try ",
            "`gcloud auth application-default login` at the command line"
        )
        warning(paste(strwrap(message), collapse = "\n"))
    }
    value
}

#' @rdname gcloud
#'
#' @description `gcloud_account()`: report the current gcloud account
#'     via `gcloud config get-value account`.
#'
#' @param account character(1) Google account (e.g., `user@gmail.com`)
#'     to use for authentication.
#'
#' @return `gcloud_account()` returns a `character(1)` vector
#'     containing the active gcloud account, typically a gmail email
#'     address.
#'
#' @importFrom BiocBaseUtils isScalarCharacter
#'
#' @examples
#' library(AnVILBase)
#' if (gcloud_exists() && identical(avplatform_namespace(), "AnVILGCP"))
#'     gcloud_account()
#'
#' @export
gcloud_account <- function(account = NULL) {
    stopifnot(is.null(account) || isScalarCharacter(account))

    if (!is.null(account))
        .gcloud_do("config", "set", "account", account)
    result <- .gcloud_do("config", "get-value", "account")
    .gcloud_get_value_check(result, "gcloud_account")
}

#' @rdname gcloud
#'
#' @description `gcloud_project()`: report the current gcloud project
#'     via `gcloud config get-value project`.
#'
#' @param project character(1) billing project name.
#'
#' @return `gcloud_project()` returns a `character(1)` vector
#'     containing the active gcloud project.
#'
#' @export
gcloud_project <- function(project = NULL) {
    stopifnot(
        is.null(project) || isScalarCharacter(project)
    )

    if (!is.null(project))
        .gcloud_do("config", "set", "project", project)
    result <- .gcloud_do("config", "get-value", "project")
    ## returns two lines when `CLOUDSDK_ACTIVE_CONFIG_NAME=`
    ## envirionment variable is set
    .gcloud_get_value_check(result, "gcloud_account")
}

#' @rdname gcloud
#'
#' @description `gcloud_help()`: queries `gcloud` for help for a
#'     command or sub-comand via `gcloud help ...`.
#'
#' @param ... Additional arguments appended to `gcloud` commands.
#'
#' @return `gcloud_help()` returns an unquoted `character()` vector
#'     representing the text of the help manual page returned by
#'     `gcloud help ...`.
#'
#' @examples
#' if (gcloud_exists() && identical(avplatform_namespace(), "AnVILGCP"))
#'     gcloud_help()
#'
#' @export
gcloud_help <- function(...)
    .gcloud_sdk_result(.gcloud_do("help", ...))

#' @rdname gcloud
#'
#' @description `gcloud_cmd()` allows arbitrary `gcloud` command
#'     execution via `gcloud ...`. Use pre-defined functions in
#'     preference to this.
#'
#' @param cmd `character(1)` representing a command used to evaluate
#'     `gcloud cmd ...`.
#'
#' @return `gcloud_cmd()` returns a `character()` vector representing
#'     the text of the output of `gcloud cmd ...`
#'
#' @export
gcloud_cmd <- function(cmd, ...)
    .gcloud_do(cmd, ...)

#' @rdname gcloud
#'
#' @description `gcloud_storage()` allows arbitrary `gcloud storage` command
#'   execution via `gcloud storage ...`. Typically used for bucket management
#'   commands such as `rm` and `cp`.
#'
#' @export
gcloud_storage <- function(cmd, ...)
    .gcloud_do("storage", cmd, ...)

#' @rdname gcloud
#'
#' @description `gcloud_storage_buckets()` provides an interface to the
#'  `gcloud storage buckets` command. This command can be used to create a new
#'   bucket via `gcloud storage buckets create ...`.
#'
#' @param bucket_cmd `character(1)` representing a buckets command typically
#'   used to create a new bucket. It can also be used to
#'   `add-iam-policy-binding` or `remove-iam-policy-binding` to a bucket.
#'
#' @param bucket `character(1)` representing a unique bucket name to be created
#'   or modified.
#'
#' @importFrom BiocBaseUtils isScalarCharacter
#' @export
gcloud_storage_buckets <- function(bucket_cmd = "create", bucket, ...) {
    stopifnot(
        isScalarCharacter(bucket_cmd), isScalarCharacter(bucket)
    )
    gcloud_storage("buckets", bucket_cmd, bucket, ...)
}
