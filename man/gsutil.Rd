% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/gsutil.R
\name{gsutil}
\alias{gsutil}
\alias{gsutil_requesterpays}
\alias{gsutil_exists}
\alias{gsutil_stat}
\alias{gsutil_rsync}
\alias{gsutil_cat}
\alias{gsutil_help}
\alias{gsutil_pipe}
\title{gsutil command line utility interface}
\usage{
gsutil_requesterpays(source)

gsutil_exists(source)

gsutil_stat(source)

gsutil_rsync(
  source,
  destination,
  ...,
  exclude = NULL,
  dry = TRUE,
  delete = FALSE,
  recursive = FALSE,
  parallel = TRUE
)

gsutil_cat(source, ..., header = FALSE, range = integer())

gsutil_help(cmd = character(0))

gsutil_pipe(source, open = "r", ...)
}
\arguments{
\item{source}{\code{character()} for \code{gsutil_requesterpays()} and
\code{gsutil_exists()}: paths to a Google Storage Bucket, possibly with
wild-cards for file-level pattern matching.}

\item{destination}{\code{character(1)}, google cloud bucket or local file system
destination path.}

\item{...}{additional arguments passed as-is to the \code{gsutil} subcommand.}

\item{exclude}{\code{character(1)} a python regular expression of bucket
paths to exclude from synchronization. E.g.,
\verb{'.*(\\\\.png|\\\\.txt)$"} excludes '.png' and .txt' files.}

\item{dry}{\code{logical(1)}, when \code{TRUE} (default), return the
consequences of the operation without actually performing the
operation.}

\item{delete}{\code{logical(1)}, when \code{TRUE}, remove files in
\code{destination} that are not in \code{source}. Exercise caution when
you use this option: it's possible to delete large amounts of
data accidentally if, for example, you erroneously reverse
source and destination.}

\item{recursive}{\code{logical(1)}; perform operation recursively from \code{source}?.
Default: \code{FALSE}.}

\item{parallel}{\code{logical(1)}, perform parallel multi-threaded /
multi-processing (default is \code{TRUE}).}

\item{header}{\code{logical(1)} when \code{TRUE} annotate each}

\item{range}{(optional) \code{integer(2)} vector used to form a range
from-to of bytes to concatenate. \code{NA} values signify
concatenation from the start (first position) or to the end
(second position) of the file.}

\item{cmd}{\code{character()} (optional) command name, e.g.,
\code{"ls"} for help.}

\item{open}{\code{character(1)} either \code{"r"} (read) or \code{"w"} (write)
from the bucket.}
}
\value{
\code{gsutil_requesterpays()}: named \code{logical()} vector TRUE
when requester-pays is enabled.

\code{gsutil_exists()}: logical(1) TRUE if bucket or object exists.

\code{gsutil_stat()}: \code{tibble()} summarizing status of each
bucket member.

\code{gsutil_rsync()}: exit status of \code{gsutil_rsync()}, invisbly.

\code{gsutil_cat()} returns the content as a character vector.

\code{gsutil_help()}: \code{character()} help text for subcommand \code{cmd}.

\code{gsutil_pipe()} an unopened R \code{pipe()}; the mode is
\emph{not} specified, and the pipe must be used in the
appropriate context (e.g., a pipe created with \code{open = "r"} for
input as \code{read.csv()})
}
\description{
These functions invoke the \code{gsutil} command line
utility. See the "Details:" section if you have gsutil
installed but the package cannot find it.

\code{gsutil_requesterpays()}: does the google bucket
require that the requester pay for access?

\code{gsutil_exists()}: check if the bucket or object
exists.

\code{gsutil_stat()}: print, as a side effect, the status
of a bucket, directory, or file.

\code{gsutil_rsync()}: synchronize a source and a
destination. If the destination is on the local file system, it
must be a directory or not yet exist (in which case a directory
will be created).

\code{gsutil_cat()}: concatenate bucket objects to standard output

\code{gsutil_help()}: print 'man' page for the \code{gsutil}
command or subcommand. Note that only commandes documented on this
R help page are supported.

\code{gsutil_pipe()}: create a pipe to read from or write
to a gooogle bucket object.
}
\details{
The \code{gsutil} system command is required.  The search for
\code{gsutil} starts with environment variable \code{GCLOUD_SDK_PATH}
providing a path to a directory containing a \code{bin} directory
containingin \code{gsutil}, \code{gcloud}, etc. The path variable is
searched for first as an \code{option()} and then system
variable. If no option or global variable is found,
\code{Sys.which()} is tried. If that fails, \code{gsutil} is searched for
on defined paths. On Windows, the search tries to find
\verb{Google\\\\Cloud SDK\\\\google-cloud-sdk\\\\bin\\\\gsutil.cmd} in the
\verb{LOCAL APP DATA}, \verb{Program Files}, and \verb{Program Files (x86)}
directories.  On linux / macOS, the search continues with
\verb{~/google-cloud-sdk}.

\verb{gsutil_rsync()': To make }"gs://mybucket/data"\verb{match the contents of the local directory}"data"` you could do:

\code{gsutil_rsync("data", "gs://mybucket/data", delete = TRUE)}

To make the local directory "data" the same as the contents of
gs://mybucket/data:

\code{gsutil_rsync("gs://mybucket/data", "data", delete = TRUE)}

If \code{destination} is a local path and does not exist, it will be
created.
}
\examples{
src <-
  "gs://genomics-public-data/1000-genomes/other/sample_info/sample_info.csv"
library(AnVILBase)
if (gcloud_exists() && identical(avplatform_namespace(), "AnVILGCP"))
    gsutil_requesterpays(src) # FALSE -- no cost download

if (gcloud_exists() && identical(avplatform_namespace(), "AnVILGCP")) {
    gsutil_exists(src)
    gsutil_stat(src)
    avlist(dirname(src))
}

if (gcloud_exists() && identical(avplatform_namespace(), "AnVILGCP"))
    gsutil_help("ls")

if (gcloud_exists() && identical(avplatform_namespace(), "AnVILGCP")) {
    df <- read.csv(gsutil_pipe(src), 5L)
    class(df)
    dim(df)
    head(df)
}

}
